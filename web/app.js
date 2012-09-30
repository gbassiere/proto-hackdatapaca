var map;
function init() {
    map = new OpenLayers.Map('map', {projection: new OpenLayers.Projection('EPSG:3857')});
    map.addLayer(new OpenLayers.Layer.OSM('Fond de plan'));
    map.addLayer(new OpenLayers.Layer.WMS('Grille', 'http://localhost:8080/geoserver/ows', {layers: 'hdp:grid', transparent: true}));
    map.setCenter(new OpenLayers.LonLat(601125, 5357740), 12);
}
OpenLayers.Event.observe(window, 'load', init);
