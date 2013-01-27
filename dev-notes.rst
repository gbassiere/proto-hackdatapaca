..  Copyright © 2012 Gilles Bassière
    This work is free. You can redistribute it and/or modify it under the
    terms of the Do What The Fuck You Want To Public License, Version 2,
    as published by Sam Hocevar. See the COPYING file for more details.

Initialiser la grille
---------------------

::

    -- Créer les cellules de la grille de visualisation (couvrant Marseille avec une maille de 500m)
    DO LANGUAGE plpgsql $$
    DECLARE
        xmin integer := 587000;
        ymin integer := 5344000;
        xmax integer := 616000;
        ymax integer := 5371000;
        step integer := 500;
        x integer;
        y integer;
        query text;
    BEGIN
        x := xmin;
        LOOP
            y := ymin;
            LOOP
                query := format('INSERT INTO grid (cell) VALUES (''SRID=3857;POLYGON((%1$s %2$s, %1$s %4$s, %3$s %4$s, %3$s %2$s, %1$s %2$s))''::geometry)', x, y, x+step, y+step);
                EXECUTE query;
                y := y + step;
                EXIT WHEN y >= ymax;
            END LOOP;
            x := x + step;
            EXIT WHEN x >= xmax;
        END LOOP;
    END;
    $$;

Intégration des données école
-----------------------------

Données obtenues sur data.gouv.fr :
http://www.data.gouv.fr/var/download/dbfdcf505d3153db75f968079442dc5a.csv

Creation de la table dans PostGIS::

    CREATE TABLE ecole (
        id char(8) PRIMARY KEY,
        nom varchar,
        x float,
        y float,
        nature varchar);

Nettoyage dans OpenOffice :

* supprimer les colonnes inutiles (celles qui ne sont pas dans la table
  ci-dessus)
* pour trouver les lignes inutiles : ordonner sur la colonne des X pour grouper
  les lignes qui ont des 0 ou du texte ou autre chose que des coordonnées,
  pareil pour la colonne des Y

Retour dans ``psql`` pour le reste du traitement ::

    -- Copie du fichier CSV vers la table
    \copy ecole
        FROM 'dbfdcf505d3153db75f968079442dc5a.csv'
        WITH CSV HEADER DELIMITER ';' ENCODING 'LATIN-1';
    -- Ajouter une colonne de type géométrique et y mettre un point calculé à partir des X et Y
    ALTER TABLE ecole
        ADD geom geometry(Point, 3857);
    UPDATE ecole
        SET geom = ST_Transform(ST_SetSRID(ST_MakePoint(x, y), 2154), 3857);
    -- Supprimer tout ce qui n'est pas dans l'emprise du projet
    DELETE FROM ecole
        USING (
            SELECT ST_SetSRID(ST_Extent(cell), 3857) as bbox FROM grid
        ) as sub
        WHERE NOT ST_Intersects(sub.bbox, geom);

    -- Attacher les données aux cellules de la grille
    -- École maternelle
    UPDATE grid g SET ecole1 = least(4, sub.val)
    FROM (
        SELECT id, sum(val) as val FROM (
            SELECT sg.id as id, 2 as val FROM grid sg, ecole e WHERE e.nature like '%MATERNELLE%' AND ST_Within(e.geom, sg.cell)
            UNION
            SELECT sg.id as id, 1 as val FROM grid sg, ecole e WHERE e.nature like '%MATERNELLE%' AND NOT ST_Within(e.geom, sg.cell) AND ST_Distance(sg.cell, e.geom) < 200
        ) as ssub GROUP BY id
    ) as sub WHERE sub.id = g.id;
    -- École élémentaire
    UPDATE grid g SET ecole2 = least(4, sub.val)
    FROM (
        SELECT id, sum(val) as val FROM (
            SELECT sg.id as id, 2 as val FROM grid sg, ecole e WHERE e.nature like '%ELEMENTAIRE%' AND ST_Within(e.geom, sg.cell)
            UNION
            SELECT sg.id as id, 1 as val FROM grid sg, ecole e WHERE e.nature like '%ELEMENTAIRE%' AND NOT ST_Within(e.geom, sg.cell) AND ST_Distance(sg.cell, e.geom) < 200
        ) as ssub GROUP BY id
    ) as sub WHERE sub.id = g.id;
    -- Collège
    UPDATE grid g SET ecole3 = least(4, sub.val)
    FROM (
        SELECT id, sum(val) as val FROM (
            SELECT sg.id as id, 2 as val FROM grid sg, ecole e WHERE e.nature like '%COLLEGE%' AND ST_Within(e.geom, sg.cell)
            UNION
            SELECT sg.id as id, 1 as val FROM grid sg, ecole e WHERE e.nature like '%COLLEGE%' AND NOT ST_Within(e.geom, sg.cell) AND ST_Distance(sg.cell, e.geom) < 200
        ) as ssub GROUP BY id
    ) as sub WHERE sub.id = g.id;
    -- Lycée
    UPDATE grid g SET ecole4 = least(4, sub.val)
    FROM (
        SELECT id, sum(val) as val FROM (
            SELECT sg.id as id, 2 as val FROM grid sg, ecole e WHERE e.nature like '%LYCEE%' AND ST_Within(e.geom, sg.cell)
            UNION
            SELECT sg.id as id, 1 as val FROM grid sg, ecole e WHERE e.nature like '%LYCEE%' AND NOT ST_Within(e.geom, sg.cell) AND ST_Distance(sg.cell, e.geom) < 200
        ) as ssub GROUP BY id
    ) as sub WHERE sub.id = g.id;

Intégration des données sur les lieux de culte
----------------------------------------------

Données OpenStreetMap obtenues avec la XAPI :
http://api.openstreetmap.fr/xapi/api/0.6/?*[amenity=place_of_worship][bbox=5.34,43.16,5.43,43.55]

Intégration dans PostgreSQL::

    osm2pgsql -d hackdatapaca -p osm -E 3857 -U gba -P 5433 -H localhost culte.osm

Post-traitement directement dans la base, via ``psql``::

    CREATE TABLE culte (
        id bigint PRIMARY KEY,
        nom varchar,
        religion varchar,
        geom geometry(Point, 3857));
    -- Copier les données ponctuelles
    INSERT INTO culte
        SELECT osm_id, name, religion, way
        FROM osm_point
        WHERE religion IS NOT NULL;
    -- Copier les données surfaciques
    INSERT INTO culte
        SELECT osm_id, name, religion, ST_Centroid(way)
        FROM osm_polygon
        WHERE religion IS NOT NULL;
    -- Nettoyer les tables osm2pgsql
    DROP TABLE osm_point;
    DROP TABLE osm_polygon;
    DROP TABLE osm_line;
    DROP TABLE osm_roads;

    -- Attacher les données aux cellules de la grille
    -- Mosquées
    UPDATE grid g SET culte_mu = least(4, sub.val)
    FROM (
        SELECT sg.id as id, sum(case
            when ST_Distance(c.geom, sg.cell) = 0 then 4
            when ST_Distance(c.geom, sg.cell) < 500 then 2
            else 1
        end) as val FROM grid sg, culte c WHERE c.religion = 'muslim' AND ST_Distance(c.geom, sg.cell) < 1000 GROUP BY sg.id
    ) as sub WHERE sub.id = g.id;
    -- Églises
    UPDATE grid g SET culte_ch = least(4, sub.val)
    FROM (
        SELECT sg.id as id, sum(case
            when ST_Distance(c.geom, sg.cell) = 0 then 4
            when ST_Distance(c.geom, sg.cell) < 500 then 2
            else 1
        end) as val FROM grid sg, culte c WHERE c.religion = 'christian' AND ST_Distance(c.geom, sg.cell) < 1000 GROUP BY sg.id
    ) as sub WHERE sub.id = g.id;
    -- Églises
    UPDATE grid g SET culte_ju = least(4, sub.val)
    FROM (
        SELECT sg.id as id, sum(case
            when ST_Distance(c.geom, sg.cell) = 0 then 4
            when ST_Distance(c.geom, sg.cell) < 500 then 2
            else 1
        end) as val FROM grid sg, culte c WHERE c.religion = 'jewish' AND ST_Distance(c.geom, sg.cell) < 1000 GROUP BY sg.id
    ) as sub WHERE sub.id = g.id;

Intégration des données vélos
-----------------------------

Données OpenStreetMap obtenues avec la XAPI :
http://api.openstreetmap.fr/xapi/api/0.6/?node[amenity=bicycle_rental][operator=Cyclocity][bbox=5.34,43.16,5.43,43.55]

Intégration dans PostgreSQL::

    osm2pgsql -d hackdatapaca -p osm -E 3857 -U gba -P 5433 -H localhost velo.osm

Post-traitement directement dans la base, via ``psql``::

    CREATE TABLE velos (
        id bigint PRIMARY KEY,
        nom varchar,
        ref char(4),
        geom geometry(Point, 3857));
    INSERT INTO velos
        SELECT osm_id, name, ref, way
        FROM osm_point;
    DROP TABLE osm_point;
    DROP TABLE osm_polygon;
    DROP TABLE osm_line;
    DROP TABLE osm_roads;

    -- Attacher les données aux cellules de la grille
    UPDATE grid g SET velo = least(4, sub.val)
    FROM (
        SELECT sg.id as id, sum(case
            when ST_Distance(v.geom, sg.cell) = 0 then 2
            else 1
        end) as val FROM grid sg, velos v WHERE ST_Distance(v.geom, sg.cell) < 500 GROUP BY sg.id
    ) as sub WHERE sub.id = g.id;

Export de la grille
-------------------

::

    pg_dump -Ox -t grid -F p -f data.sql -a hackdatapaca

Rajouter de nouvelles données
-----------------------------

* Intégrez les données dans la base (ça dépendra du format des données, voir les
  exemples ci-dessus).
* Ajoutez une colonne ``xxx`` à la table ``grid``.
* Chaque enregistrement de la table ``grid`` représente une cellule de la grille
  de visualisation. Débrouillez vous pour calculer une valeur en 0 et 4 pour
  le champ ``xxx`` de chaque cellule en fonction de vos données.
* Modifiez la fonction SQL ``get_cell_value()`` (définie dans ``initdb.sql``)
  pour y ajouter deux arguments : ``xxx_val`` et ``xxx_ok``. Modifier le corps
  de la fonction pour intégrer ces deux arguments dans le calcul de la moyenne.
* Au niveau de GeoServer, modifiez la "vue SQL" du layer ``grid``. Dans la
  requête SQL, ajoutez le champ ``xxx`` à la place de l'argument ``xxx_val`` et
  le paramètre ``%xxx%`` à la place de l'argument ``xxx_ok``. Dans la liste des
  paramètres en dessous, ajoutez ``xxx`` avec la valeur par défaut 0 et la
  regexp de validation ``^[01]$``.
* Au niveau de l'interface, ajoutez une case à cocher avec l'id ``xxx`` dans le
  fichier ``index.html`` et ajoutez ``'xxx'`` dans le tableau ``input_ids`` au
  début du fichier ``app.js``.

Faire évoluer le prototype
--------------------------

Ce prototype n'est pas pensé pour évoluer, le développement a été fait en mode
"Quick n' Dirty" pour monter une preuve de concept en moins de 2 jours.

On s'appuie énormement sur la souplesse de GeoServer pour pouvoir monter une
application sans avoir à coder notre propre backend. Ça marche bien pour une
preuve de concept mais ça pourrait ne pas être suffisant pour une application de
production selon les choix d'architecture qui seront fait.

Bref, ne cherchez pas à faire évoluer ces bouts de code. Réflechissez
sereinement en repartant du début.
