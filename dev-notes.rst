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
    INSERT INTO culte
        SELECT osm_id, name, religion, way
        FROM osm_point
        WHERE religion IS NOT NULL;
    INSERT INTO culte
        SELECT osm_id, name, religion, ST_Centroid(way)
        FROM osm_polygon
        WHERE religion IS NOT NULL;
    DROP TABLE osm_point;
    DROP TABLE osm_polygon;
    DROP TABLE osm_line;
    DROP TABLE osm_roads;

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
