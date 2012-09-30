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

::

    sudo apt-get install tomcat6-user postgresql-9.1-postgis

Préparer la base de données
---------------------------

::

    sudo -s -u postgres
    createuser -dSR oss
    psql -c "ALTER ROLE oss PASSWORD 'oss'"
    createdb -O oss hackdatapaca
    psql -d hackdatapaca -f /usr/share/postgresql/9.1/contrib/postgis-1.5/postgis.sql
    psql -d hackdatapaca -f /usr/share/postgresql/9.1/contrib/postgis-1.5/spatial_ref_sys.sql
    psql -d hackdatapaca -f initdb.sql
    psql -d hackdatapaca -f data.sql
    psql -d hackdatapaca -c "ALTER TABLE geometry_columns OWNER TO oss"
    psql -d hackdatapaca -c "ALTER TABLE spatial_ref_sys OWNER TO oss"
    psql -d hackdatapaca -c "ALTER VIEW geography_columns OWNER TO oss"
    psql -d hackdatapaca -c "ALTER TABLE grid OWNER TO oss"
    exit

Serveur carto (installation)
----------------------------

::

    cd /ou/tu/veux/
    git clone git://github.com/gbassiere/proto-hackdatapaca.git
    cd proto-hackdatapaca
    PROJECTDIR=`pwd`
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

Charger les règles de rendu :

* Menu latéral : Styles > Ajouter une nouvelle ressource
* Cliquer sur "Ajouter un nouveau style"
* Commencer par charger le fichier ``style.sld`` : en bas du formulaire, sous la
  zone de texte, cliquer sur "Browse" pour le sélectionner puis sur "Charger",
  le fichier doit alors apparaître dans la zone de texte
* Remplissez ensuite le reste du formulaire :
* Nom : ``gridcolors``
* Espace de travail : ``hdp``
* En bas du formulaire, il est important de cliquer sur "Valider" ET sur
  "Envoyer" (le bouton "Valider" ne fait que le contôle de syntaxe, il
  n'enregistre pas).

Créer un entrepôt de type PostGIS avec les paramètres suivants :

* espace de travail : ``hdp``
* nom : ``hdp``
* activé : oui
* host : ``localhost``
* port : ``5432``
* database : ``hackdatapaca``
* user : ``oss``
* password : ``oss``

Normalement, après cette étape, GeoServer vous amène directement sur le
formulaire pour créer une couche dans cet entrepôt :

* Cliquer sur "Configure new SQL view"
* View name : ``grid``
* SQL statement:

::

    SELECT id, cell, get_cell_value(ecole1, ecole2, ecole3, ecole4, culte_mu, velo culte_ch, culte_ju, %ec1%, %ec2%, %ec3%, %ec4%, %cum%, %cuc%, %cuj%, %vel%) AS value FROM grid

* Cliquer sur "Guess parameters from SQL"
* Pour tous les paramètres trouvés, indiquer ``0`` dans "Default value" et
  ``^[01]$`` dans "Validation regular expression"
* Cliquer sur "Refresh" au dessus des attributs
* Cocher "Identifier" pour l'attribut ``id``
* Pour l'attribut ``cell``, indiquer le type "Polygon" et le SRID 3857
* Valider la source de données SQL en cliquant sur "Sauvegarder", ça doit
  vous ramener dans le formulaire de création du layer
* Dans l'onglet "Données", indiquer le nom ``grid`` puis, dans la section
  "Emprises", cliquer sur "Basées sur les données" et "Calculées sur les
  emprises natives"
* Dans l'onglet "Publication", choisir ``gridcolors`` pour le "style par
  défaut".
* En bas du formulaire, cliquer sur "Sauvegarder"

Bibliothèques tierces
---------------------

::

    cd $PROJECTDIR
    mkdir web/lib && cd web/lib
    wget http://openlayers.org/download/OpenLayers-2.12.tar.gz
    tar zxf OpenLayers-2.12.tar.gz
    rm OpenLayers-2.12.tar.gz

Configuration du serveur HTTP
-----------------------------

Choisissez un serveur HTTP (Apache, Nginx, ...) et configurez-le pour :

* Servir à la racine les fichiers statiques du répertoire ``web/``.
* Rediriger ``/geoserver`` vers ``http://localhost:8080/geoserver`` (proxy).

Lancer le bouzin
================

::

    cd $PROJECTDIR
    ./tomcat_instance/bin/startup.sh

Lancez aussi le serveur HTTP que vous avez choisi, évidemment.
