# frozen_string_literal: true

module Weather
  class Error < StandardError; end

  class ApiClientService
    include HTTParty

    base_uri ENV.fetch('WEATHER_API_BASE')

    headers 'Content-Type' => 'application/json'

    # Check weather for a location.
    #
    # @param lat [Integer] is the Latitude.
    # @param lon [Integer] is the Longitude
    # @return the parsed response of the API.
    def query_by_position(latitude:, longitude:)
      raise ArgumentError, 'parametter is missing' if latitude.blank? || longitude.blank?

      response = execute_request('get',
                                 "/data/3.0/onecall?#{query_params_position(latitude, longitude)}")
      unless success_response?(response)
        error_detail = fetch_error_message(response.parsed_response)
        raise Error, unknown_location_message(latitude, longitude, error_detail)
      end

      response.parsed_response
    end

    # Get position for a city.
    #
    # @param city [String]
    # @param country [String]
    # @return the parsed response of the API.
    def query_position_for_city(city:, state:, country:)
      raise ArgumentError, 'parametter is missing' if city.blank? || country.blank? || state.blank?

      query_params = query_params_city(city, state, country)
      response = execute_request('get', "/geo/1.0/direct?q=#{query_params}")
      raise Error, "Unknown error #{response.parsed_response}" unless success_response?(response)

      parsed_response = response.parsed_response
      raise Error, unknown_city_message(city, state, country) if parsed_response.empty?

      parsed_response
    end

    private

    attr_reader :api_key

    def query_params_position(latitude, longitude)
      "lat=#{latitude}&lon=#{longitude}&units=imperial&appid=#{api_access_token}"
    end

    def query_params_city(city, state, country)
      "#{city},#{state},#{country}&limit=1&appid=#{api_access_token}"
    end

    def api_access_token
      @api_access_token ||= ENV.fetch('WEATHER_API_ACCESS_TOKEN')
    end

    def execute_request(method, url, body = nil)
      options = { body: body&.to_json }.compact

      self.class.send(method, url, options)
    end

    def success_response?(response)
      response.code == 200
    end

    def fetch_error_message(error_response)
      "#{error_response['message']}. Check parameter/s: #{error_response['parameters']&.join(',')}"
    end

    def unknown_location_message(latitude, longitude, error_detail)
      "Could not retrieve weather for [latitude: #{latitude}, longitude #{longitude}}]. " \
        "Details: #{error_detail}"
    end

    def unknown_city_message(city, state, country)
      "Unknown city #{city} for state #{state} and country #{country}"
    end
  end
end
