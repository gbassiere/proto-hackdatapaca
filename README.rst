Contributeurs
=============

* Antoine Guyon
* Gilles Bassière
* Grégory Colpart
* Mathilde Dioudonnat
* Romaric Seglat
* Vaidotas Zinkevicius

Installation
============

Environnement
-------------

Prototype testé sous Ubuntu 12.04

Paquets à installer
-------------------

:code:

    sudo apt-get install tomcat6-user postgresql-9.1-postgis

Préparer la base de données
---------------------------

:code:

    createdb hackdatapaca
    psql -d hackdatapaca -c "CREATE EXTENSION postgis;"
    psql -d hackdatapaca -f initdb.sql
    psql -d hackdatapaca -f data.sql

Serveur carto (installation)
----------------------------

:code:

    PROJECTDIR=ou/tu/veux/
    cd $PROJECTDIR
    tomcat6-instance-create tomcat_instance
    cd tomcat_instance/webapps/
    wget http://downloads.sourceforge.net/geoserver/geoserver-2.2-war.zip
    unzip geoserver-2.2-war.zip
    rm geoserver-2.2-war.zip
    cd ../..
    ./tomcat_instance/bin/startup.sh

Serveur carto (configuration)
-----------------------------

Aller sur l'interface d'administration de GeoServer, normalement sur :
http://localhost:8080/geoserver/web/

Supprimer les objets de démonstration (supprimer "espaces de travail" devraient
suffire à détruire tout les objets en cascade).

Créer un espace de travail nommé ``hdp``.

Créer un entrepôt de type PostGIS avec les paramètres suivants :

* espace de travail : ``hdp``
* nom : ``hdp``
* activé : oui
* host : ``localhost``
* port : ``5432``
* database : ``hackdatapaca``
* user : celui que vous avez configuré
* password : celui que vous avez configuré

Créer une couche :

* Menu latéral : Couches > Ajouter une nouvelle ressource
* Choisir l'entrepôt ``hdp:hdp``
* Cliquer sur "Configure new SQL view"
* View name : ``grid``
* SQL statement :

    SELECT id, cell, get_cell_value(ecole1, ecole2, ecole3, ecole4, culte_mu, velo
    culte_ch, culte_ju, %ec1%, %ec2%, %ec3%, %ec4%, %cum%, %cuc%, %cuj%, %vel%)
    AS value FROM grid

* Cliquer sur "Guess parameters from SQL"
* Pour tous les paramètres trouvés, indiquer ``0`` dans "Default value" et
  ``^[01]$`` dans "Validation regular expression"
* Cliquer sur "Refresh" au dessus des attributs
* Cocher "Identifier" pour l'attribut ``id``
* Pour l'attribut ``cell``, indiquer le type "Polygon" et le SRID 3857
* Bien valider en cliquant sur "Sauvegarder" sous le formulaire de la vue SQL et
  une deuxième fois sous le formulaire du nouveau layer.

Bibliothèques tierces
---------------------

:code:

    cd $PROJECTDIR
    mkdir web/lib && cd web/lib
    wget http://openlayers.org/download/OpenLayers-2.12.tar.gz
    tar zxf OpenLayers-2.12.tar.gz
    rm OpenLayers-2.12.tar.gz


Lancer le bouzin
================

:code:

    cd $PROJECTDIR
    ./tomcat_instance/bin/startup.sh
    cd web/
    python -m SimpleHTTPServer
