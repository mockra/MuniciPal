function getDistrictsGeom() {
  $.ajax({
    type: 'GET',
    url: 'https://services2.arcgis.com/1gVyYKfYgW5Nxb1V/ArcGIS/rest/services/MesaCouncilDistricts/FeatureServer/0/query?where=objectid+%3D+objectid&outfields=*&f=json',
    dataType: 'json',
    success: function(geom) {
	  geom.features.map(function(feature) { g_districts_tom.push(Terraformer.ArcGIS.parse(feature));})
	  g_json = {"type":"FeatureCollection", "features":g_districts_tom }
    }
  });
}
// get 1 district     url: 'https://services2.arcgis.com/1gVyYKfYgW5Nxb1V/ArcGIS/rest/services/MesaCouncilDistricts/FeatureServer/0/query?where=DISTRICT%3D'+district_id+'&f=json',
//       geoJSON.properties = { fill: config.map.district_fill };
      // districtLayer.setGeoJSON(geoJSON);
      // districtLayer.setFilter(function() { return true; });
