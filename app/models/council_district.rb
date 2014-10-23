class CouncilDistrict < ActiveRecord::Base
  has_many :event_items

  COORD_SYS_REF = 4326;   # The coordinate system that will be used as the reference and is now Latitude and lngitude Coord System

  # THE COMMENTED EXAMPLE BELOW USES FARADAY INSTEAD OF THE ARCGIS GEM--SEEMS PREFERABLE TO GO WITH A SUPPORTED GEM FOR THE API
  # def self.getDistrict lat, lng
  #
  #   # figure out if it is in a specific area in
  #   # @spec_area = CouncilDistrict.where(
  #   #   "ST_Contains(geom, ST_SetSRID(ST_MakePoint(?, ?),#{COORD_SYS_REF}))",
  #   #   lng, lat)
  #
  #   @url = 'https://services2.arcgis.com/'
  #
  #   @connection = Faraday.new(url: @url ) do |conn|
  #     conn.headers['Accept'] = 'text/json'
  #     conn.request :instrumentation
  #     conn.response :json
  #     conn.adapter Faraday.default_adapter
  #     conn.request :retry, max: 5, interval: 0.05, interval: 0.05, interval_randomness: 0.5, backoff_factor: 2
  #   end
  #
  #   @userpoint = CGI::escape(lng.to_s + ','+ lat.to_s)
  #   @response = @connection.get '1gVyYKfYgW5Nxb1V/ArcGIS/rest/services/MesaCouncilDistricts/FeatureServer/0/query?geometry=' +
  #                               @userpoint +
  #                               '&geometryType=esriGeometryPoint&inSR=4326&spatialRel=esriSpatialRelIntersects&units=esriSRUnit_Meter&outFields=&returnGeometry=false&f=json'
  #   # example response
  #   # {"objectIdFieldName"=>"OBJECTID", "globalIdFieldName"=>"", "geometryType"=>"esriGeometryPolygon", "spatialReference"=>{"wkid"=>2868, "latestWkid"=>2868}, "fields"=>[], "features"=>[{"attributes"=>{"DISTRICTS"=>"DISTRICT 1"}}]}
  #   # example nil response
  #   # {"objectIdFieldName"=>"OBJECTID", "globalIdFieldName"=>"", "features"=>[]}
  #
  #   if @response.body["features"].empty?
  #     @district_data = nil
  #   else
  #     @district_number = @response.body["features"][0]["attributes"]["DISTRICTS"][-1,1]
  #     @district_data = CouncilDistrict.find(@district_number)
  #   end
  #
  #   return @district_data
  # end

  def self.getDistrict lat, lng
    service_url = "https://services2.arcgis.com/1gVyYKfYgW5Nxb1V/ArcGIS/rest/services/MesaCouncilDistricts/FeatureServer"
    service = Geoservice::MapService.new(url: service_url)
    params = {
      geometry: [lng,lat].join(','),
      geometryType: "esriGeometryPoint",
      inSR: 4326,
      spatialRel: "esriSpatialRelIntersects",
      units: "esriSRUnit_Meter",
      returnGeometry: false
    }
    @response = service.query(0, params)
    puts @response["features"]

    if @response["features"].empty?
      @district_data = nil
    else
      @district_number = @response["features"][0]["attributes"]["DISTRICTS"][-1,1]
      @district_data = CouncilDistrict.find(@district_number)
    end
    return @district_data
  end

  # def self.getDistricts
  #   # The user might want to map all the districts, so send 'em all.
  #   @districts_as_geojson = CouncilDistrict.find_by_sql(
  #     "select id, name, twit_name, twit_wdgt, ST_AsGeoJSON(geom) as geom
  #       from council_districts");
  #   return @districts_as_geojson;
  # end

  # def self.point_in_district district
  #   @point = ActiveRecord::Base.connection.select_one(
  #     "WITH results as (
  #       SELECT ST_PointOnSurface(geom) as point from council_districts where id = #{district}
  #     ) SELECT ST_X(point) as lng, ST_Y(point) as lat from results"
  #   )
  #   @point = @point.merge(@point) { |k,v| v.to_f } #string to float on all hash values
  #   return @point
  # end


end
