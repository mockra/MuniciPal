class CouncilDistrict < ActiveRecord::Base
  has_many :event_items

  COORD_SYS_REF = 4326;   # The coordinate system that will be used as the reference and is now Latitude and Longitude Coord System

  def self.bypoint lat, long
    service_url = "https://services2.arcgis.com/1gVyYKfYgW5Nxb1V/ArcGIS/rest/services/MesaAzCouncilDistricts/FeatureServer"
    service = Geoservice::MapService.new(url: service_url)
    params = {
      geometry: [long,lat].join(','),
      geometryType: "esriGeometryPoint",
      inSR: 4326,
      spatialRel: "esriSpatialRelIntersects",
      units: "esriSRUnit_Meter",
      returnGeometry: false
    }
    query = service.query(0, params)
    puts query["features"]
    return query["features"]
  end

  def self.inDistrict? lat, long

    # figure out if it is in a specific area in
    # @spec_area = CouncilDistrict.where(
    #   "ST_Contains(geom, ST_SetSRID(ST_MakePoint(?, ?),#{COORD_SYS_REF}))",
    #   long, lat)

    @url = 'https://services2.arcgis.com/'

    @connection = Faraday.new(url: @url ) do |conn|
      conn.headers['Accept'] = 'text/json'
      conn.request :instrumentation
      conn.response :json
      conn.adapter Faraday.default_adapter
      conn.request :retry, max: 5, interval: 0.05, interval: 0.05, interval_randomness: 0.5, backoff_factor: 2
    end

    @userpoint = CGI::escape(long.to_s + ','+ lat.to_s)
    @response = @connection.get '1gVyYKfYgW5Nxb1V/ArcGIS/rest/services/MesaAzCouncilDistricts/FeatureServer/2/query?geometry=' +
                                @userpoint +
                                '&geometryType=esriGeometryPoint&inSR=4326&spatialRel=esriSpatialRelIntersects&units=esriSRUnit_Meter&outFields=&returnGeometry=false&f=json'
    # example response
    # {"objectIdFieldName"=>"OBJECTID", "globalIdFieldName"=>"", "geometryType"=>"esriGeometryPolygon", "spatialReference"=>{"wkid"=>2868, "latestWkid"=>2868}, "fields"=>[], "features"=>[{"attributes"=>{"DISTRICTS"=>"DISTRICT 1"}}]}
    # example nil response
    # {"objectIdFieldName"=>"OBJECTID", "globalIdFieldName"=>"", "features"=>[]}

    @spec_area = @response.body["features"]
    return !@spec_area.empty?
  end

  def self.getDistrict lat, long
    # figure out if it is in a specific area in historical district

    @url = 'https://services2.arcgis.com/'

    @connection = Faraday.new(url: @url ) do |conn|
      conn.headers['Accept'] = 'text/json'
      conn.request :instrumentation
      conn.response :json
      conn.adapter Faraday.default_adapter
      conn.request :retry, max: 5, interval: 0.05, interval: 0.05, interval_randomness: 0.5, backoff_factor: 2
    end

    @userpoint = CGI::escape(long.to_s + ','+ lat.to_s)
    @response = @connection.get '1gVyYKfYgW5Nxb1V/ArcGIS/rest/services/MesaAzCouncilDistricts/FeatureServer/2/query?geometry=' +
                                @userpoint +
                                '&geometryType=esriGeometryPoint&inSR=4326&spatialRel=esriSpatialRelIntersects&units=esriSRUnit_Meter&outFields=&returnGeometry=false&f=json'

    @district_number = @response.body["features"][0]["attributes"]["DISTRICTS"][-1,1]

    @area_in_geojson = CouncilDistrict.find(@district_number)

    return @area_in_geojson
  end

  # def self.getDistricts
  #   # The user might want to map all the districts, so send 'em all.
  #   @districts_as_geojson = CouncilDistrict.find_by_sql(
  #     "select id, name, twit_name, twit_wdgt, ST_AsGeoJSON(geom) as geom
  #       from council_districts");
  #   return @districts_as_geojson;
  # end

  def self.point_in_district district
    @point = ActiveRecord::Base.connection.select_one(
      "WITH results as (
        SELECT ST_PointOnSurface(geom) as point from council_districts where id = #{district}
      ) SELECT ST_X(point) as lng, ST_Y(point) as lat from results"
    )
    @point = @point.merge(@point) { |k,v| v.to_f } #string to float on all hash values
    return @point
  end


end
