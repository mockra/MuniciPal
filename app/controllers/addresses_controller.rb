require 'geokit'

class AddressesController < ApplicationController

  respond_to :html, :json

  def index
#   fill this out and set it along the way
    @response = { :lat                    => nil,
                  :lng                    => nil,
                  :address                => "",
                  :in_district       => false,
                  :person_title      => "",
                  :district       => nil,
                  :event_items       => nil,
                  :attachments => nil,
                  :events => nil
                }

    #SET THE VALUES IN THE RESPONSE TO THEIR VALUES IN THE PARAMS
    @response.each_key{|key| @response[key.to_sym] = params[key.to_sym]}

    #move block below to own route? - seem like params' key should be :title, not :title.value?
    # /people/byTitle/:title (title = mayor, manager, councilmember, all)
    if params[:mayor]
      @response[:person_title] = "mayor"
    elsif params[:manager]
      @response[:person_title] = "manager"
    else
      @response[:person_title] = "councilmember"
    end


    # district given
#/districts/byId/:id/ -> { person + things}, where things = event_items (including attachments), and events
    if not @response[:district].blank?

      @response[:in_district] = true

      if @response[:district] == "all"
        # puts "mayor or manager!"
        # @mayor = true
        # @district_id = 0 # 0 means mayor
        #marker_location = [33.42, -111.835]
        # use lat/lon at center of Mesa
        @response[:lat] = 33.42
        @response[:lng] = -111.835
        @location = { lat: @response[:lat], lng: @response[:lng] }
      else
        # NEED TO REPLACE THIS
        # find lat/lon at center of polygon
        # any_point = CouncilDistrict.point_in_district params[:district]
        # @lat = any_point["lat"]
        # @lng = any_point["lng"]
      end

      # find address at given lat/lon
      # @address = Geokit::Geocoders::MultiGeocoder.reverse_geocode "#{@lat}, #{@lng}"
    end

    # address given; geocode to get lat/lon
# /districts/byAddress/:address -> lat,lon


    if not @response[:address].blank?
    #if address is given:
      @geocoded_address = Geokit::Geocoders::MultiGeocoder.geocode @response[:address]
      @response[:lat] = @geocoded_address.lat
      @lng = @geocoded_address.lng
      @location = { lat: @response[:lat], lng: @response[:lng] }
    elsif (not @response[:lat].blank? and not @response[:lng].blank?)
    #if lat and lng are given or geocoded from address
      @response[:lat] = @response[:lat]
      @response[:lng] = @response[:lng]
      @location = { lat: @response[:lat], lng: @response[:lng] }
    end

    if @location
      @district_json = CouncilDistrict.getDistrict @location[:lat], @location[:lng] #@lat, @lng
      @response[:in_district] = !@district_json[:district].nil?
      @response[:district] = @district_json.id if @response[:in_district]
    end

    if not @response[:district].blank?
      #NOT SURE WE NEED THIS LINE BELOW - THE JSON ISN'T USED FOR ANYTHING
      @district_json = CouncilDistrict.find(@response[:district])
      @response[:in_district] = true
    end


    if @district
      @event_items = EventItem.current.with_matters.in_district(@district.id).order('date DESC') +
                     EventItem.current.with_matters.no_district.order('date DESC') if @response[:in_district]
    end



    # if not params[:address].blank?
    #   @geocoded_address = Geokit::Geocoders::MultiGeocoder.geocode params[:address]
    #   @lat = @geocoded_address.lat
    #   @lng = @geocoded_address.lng
    #
    #   @district = CouncilDistrict.getDistrict @lat, @lng
    #   @in_district = !@district.nil?
    #
    #   @event_items = EventItem.current.with_matters.in_district(@district.id).order('date DESC') +
    #                  EventItem.current.with_matters.no_district.order('date DESC') unless @in_district == FALSE
    #   @district_id = @district.id unless @in_district == FALSE
    # end
    #
    # # lat/lon given, reverse geocode to find address
    # if not params[:lat].blank? and not params[:lng].blank?
    #   @lat = params[:lat]
    #   @lng = params[:lng]
    #
    #   #@address = Geokit::Geocoders::MultiGeocoder.reverse_geocode "#{params[:lat]}, #{params[:lng]}"
    #   @district = CouncilDistrict.getDistrict @lat, @lng
    #   @in_district = !@district.nil?
    #
    #   @event_items = EventItem.current.with_matters.in_district(@district.id).order('date DESC') +
    #                  EventItem.current.with_matters.no_district.order('date DESC') unless @in_district == FALSE
    #   @district_id = @district.id unless @in_district == FALSE
    # end

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

#    @addr = @geocoded_address.full_address if @geocoded_address

    if @response[:person_title] == "mayor" or @response[:person_title] == "manager"
      @event_items = EventItem.current.with_matters.order('date DESC') #all
      @response[:district] = nil
        if !@response[:lat] or !@response[:lng]
          @response[:lat] = 33.42
          @response[:lng] = -111.835
          #the following line is a legacy thing from a variable in JS that flags whether a user was in the city
          @response[:in_district] = true;
          # @district_polygon = CouncilDistrict.getDistrict @lat, @lng
          # if @district_polygon and @district_polygon.id
          #   @district_id = @district_id.id
          # end
        end
    end

    #
    # # only build a response if user asks for something specific
    # # the following line checks that the submitted parameters match at least one of the variables listed in the array
    # if (['district', 'mayor', 'address', 'manager', 'lat', 'lon'] & params.keys).length > 0
    #   @response = { :lat                    => @location[:lat], #@lat,
    #                 :lng                    => @location[:lng], #@lng,
    #                 :address                => @addr,
    #                 :in_district       => @in_district,
    #                 :person_title      => @person_title,
    #                 :district       => @district_id,
    #                 :event_items       => @event_items,
    #                 :attachments => attachments,
    #                 :events => events
    #               }
    # else
    #   @response = {}
    # end

    respond_with(@response)
  end
end
