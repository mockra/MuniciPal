require 'geokit'

class AddressesController < ApplicationController

  respond_to :html, :json

  def index
    @in_district = false
    @lat = nil, @lng = nil, @address = nil


# /people/byTitle/:title (title = mayor, manager, councilmember, all)
    if params[:mayor]
      @person_title = "mayor"
    elsif params[:manager]
      @person_title = "manager"
    else
      @person_title = "councilmember"
    end

    # district given
#/districts/byId/:id/ -> { person + things}, where things = event_items (including attachments), and events
    if not params[:district].blank?

      @in_district = true

      if params[:district] == "all"
        # puts "mayor or manager!"
        # @mayor = true
        # @district_id = 0 # 0 means mayor
        #marker_location = [33.42, -111.835]
        # use lat/lon at center of Mesa
        @lat = 33.42
        @lng = -111.835
      else
        # find lat/lon at center of polygon
        any_point = CouncilDistrict.point_in_district params[:district]
        @lat = any_point["lat"]
        @lng = any_point["lng"]
      end

      # find address at given lat/lon
      # @address = Geokit::Geocoders::MultiGeocoder.reverse_geocode "#{@lat}, #{@lng}"
    end

    # address given; geocode to get lat/lon
# /districts/byAddress/:address -> lat,lon

    if not params[:address].blank?
      @geocoded_address = Geokit::Geocoders::MultiGeocoder.geocode params[:address]
      @lat = @geocoded_address.lat
      @lng = @geocoded_address.lng

      @district = CouncilDistrict.getDistrict @lat, @lng
      @in_district = !@district.nil?

      @event_items = EventItem.current.with_matters.in_district(@district.id).order('date DESC') +
                     EventItem.current.with_matters.no_district.order('date DESC') unless @in_district == FALSE
      @district_id = @district.id
    end

    # lat/lon given, reverse geocode to find address
    if not params[:lat].blank? and not params[:long].blank?
      @lat = params[:lat]
      @lng = params[:long]

      #@address = Geokit::Geocoders::MultiGeocoder.reverse_geocode "#{params[:lat]}, #{params[:long]}"
      @district = CouncilDistrict.getDistrict @lat, @lng
      @in_district = !@district.nil?

      @event_items = EventItem.current.with_matters.in_district(@district.id).order('date DESC') +
                     EventItem.current.with_matters.no_district.order('date DESC') unless @in_district == FALSE
      @district_id = @district.id
    end

#/districts/byPoint/lat,lon
    # if @address
    #   @addr = @address.full_address
    #   @district_polygon = CouncilDistrict.getDistrict @lat, @lng
    #   if @district_polygon and @district_polygon.id
    #     @district_id = @district_polygon.id
    #     @event_items = EventItem.current.with_matters.in_district(@district_polygon.id).order('date DESC') +
    #                    EventItem.current.with_matters.no_district.order('date DESC')
    #   else
    #     puts "ERROR: Whaaaaaat?! No district/id. You ran rake council_districts:load to populate the table right?"
    #   end
    # end

# /event_items/current -> includes attachments
# /events/current
    if @event_items
      attachments = @event_items.map(&:attachments) #see http://ablogaboutcode.com/2012/01/04/the-ampersand-operator-in-ruby/
      events = @event_items.map(&:event).uniq #see http://ablogaboutcode.com/2012/01/04/the-ampersand-operator-in-ruby/
    end

    if @geocoded_address
      @addr = @geocoded_address.full_address
    else
      @addr = ""
    end

    if @person_title == "mayor" or @person_title == "manager"
      @event_items = EventItem.current.with_matters.order('date DESC') #all
      @district_id = nil
        if !@lat or !@lng
          @lat = 33.42
          @lng = -111.835
          @in_district = true;
          # @district_polygon = CouncilDistrict.getDistrict @lat, @lng
          # if @district_polygon and @district_polygon.id
          #   @district_id = @district_id.id
          # end
        end
    end

    # only build a response if user asks for something specific
    # the following line checks that the submitted parameters match at least one of the variables listed in the array
    if (['district', 'mayor', 'address', 'manager', 'lat', 'lon'] & params.keys).length > 0
      @response = { :lat                    => @lat,
                    :lng                    => @lng,
                    :address                => @addr,
                    :in_district       => @in_district,
                    :person_title      => @person_title,
                    :district_id       => @district_id,
                    :event_items       => @event_items,
                    :attachments => attachments,
                    :events => events
                  }
    else
      @response = {}
    end

    respond_with(@response)
  end
end
