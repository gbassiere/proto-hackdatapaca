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

    DBNAME=hackdatapaca
    createdb $DBNAME
    psql -d $DBNAME -c "CREATE EXTENSION postgis;"

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

Bibliothèques tierces
---------------------

:code:

    cd $PROJECTDIR
    mkdir web/lib && cd web/lib
    wget http://openlayers.org/download/OpenLayers-2.12.tar.gz
    tar zxf OpenLayers-2.12.tar.gz
    rm OpenLayers-2.12.tar.gz

*À faire*: build personnalisé d'OpenLayers pour économiser des Ko.


Lancer le bouzin
================

:code:

    cd $PROJECTDIR
    ./tomcat_instance/bin/startup.sh
    cd web/
    python -m SimpleHTTPServer
