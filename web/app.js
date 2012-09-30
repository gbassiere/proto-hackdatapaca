var map, grid_layer;

function refresh() {
    params = [];
    params.push('ec1:' + Number($('ec1').checked));
    params.push('ec2:' + Number($('ec2').checked));
    params.push('ec3:' + Number($('ec3').checked));
    params.push('ec4:' + Number($('ec4').checked));
    params.push('cum:' + Number($('cum').checked));
    params.push('cuc:' + Number($('cuc').checked));
    params.push('cuj:' + Number($('cuj').checked));
    grid_layer.params['VIEWPARAMS'] = params.join(';');
    grid_layer.redraw();
}

function init() {
    map = new OpenLayers.Map('map', {projection: new OpenLayers.Projection('EPSG:3857')});
    map.addLayer(new OpenLayers.Layer.OSM('Fond de plan'));
    grid_layer = new OpenLayers.Layer.WMS(
        'Grille',
        'http://localhost:8080/geoserver/ows',
        {layers: 'hdp:grid', transparent: true},
        {visibility: false}
    )
    map.addLayer(grid_layer);
    map.setCenter(new OpenLayers.LonLat(601125, 5357740), 12);

    var input_ids = ['ec1', 'ec2', 'ec3', 'ec4', 'cum', 'cuc', 'cuj'];
    for (var i in input_ids) {
        OpenLayers.Event.observe($(input_ids[i]), 'change', refresh);
    }

    refresh();
    grid_layer.setVisibility(true);
}

OpenLayers.Event.observe(window, 'load', init);
