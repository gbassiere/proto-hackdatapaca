var map;
function init() {
    map = new OpenLayers.Map('map', {projection: new OpenLayers.Projection('EPSG:3857')});
    map.addLayer(new OpenLayers.Layer.OSM('Fond de plan'));
    map.addLayer(new OpenLayers.Layer.WMS(
        'Grille',
        'http://localhost:8080/geoserver/ows',
        {layers: 'hdp:grid', transparent: true, viewparams: 'ec1:1;ec2:0;ec3:1;ec4:0;cum:1;cuc:0;cuj:0'}
    ));
    map.setCenter(new OpenLayers.LonLat(601125, 5357740), 12);
}
OpenLayers.Event.observe(window, 'load', init);
