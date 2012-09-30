var map, grid_layer;

var input_ids = ['ec1', 'ec2', 'ec3', 'ec4', 'cum', 'cuc', 'cuj', 'vel'];

function refresh() {
    params = [];
    for (var i in input_ids) {
        params.push(input_ids[i] + ':' + Number($(input_ids[i]).checked));
    }
    grid_layer.params['VIEWPARAMS'] = params.join(';');
    grid_layer.redraw();
}

function init() {
    map = new OpenLayers.Map('map', {projection: new OpenLayers.Projection('EPSG:3857')});
    map.addLayer(new OpenLayers.Layer.OSM('Fond de plan'));
    grid_layer = new OpenLayers.Layer.WMS(
        'Grille',
        '/geoserver/ows',
        {layers: 'hdp:grid', transparent: true},
        {visibility: false}
    )
    map.addLayer(grid_layer);
    map.setCenter(new OpenLayers.LonLat(601125, 5357740), 12);

    for (var i in input_ids) {
        OpenLayers.Event.observe($(input_ids[i]), 'change', refresh);
    }

    refresh();
    grid_layer.setVisibility(true);
}

OpenLayers.Event.observe(window, 'load', init);
