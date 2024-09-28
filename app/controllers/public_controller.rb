# frozen_string_literal: true

class PublicController < ApplicationController
  def index; end

  def query_by_position
    render turbo_stream: turbo_stream.replace(
      'current-weather', partial: 'weather', locals: { weather: check_weather_service }
    )
  end

  def query_by_city
    render turbo_stream: turbo_stream.replace(
      'city-weather', partial: 'weather', locals: { weather: check_weather_service_for_city }
    )
  end

  def states
    @options = options_for_select
    @target = permitted_params_for_location[:target]
  end

  private

  def permitted_params_for_weather
    params.permit(:lat, :long)
  end

  def permitted_params_for_location
    params.permit(:country, :state, :target)
  end

  def options_for_select
    if permitted_params_for_location[:country].present?
      CS.states(permitted_params_for_location[:country]).invert
    elsif permitted_params_for_location[:state].present?
      CS.cities(permitted_params_for_location[:state])
    else
      []
    end
  end

  def check_weather_service
    Weather::CheckWeatherService.new.query_by_position(
      latitude: permitted_params_for_weather[:lat], longitude: permitted_params_for_weather[:long]
    )['weather_overview']
  end

  def check_weather_service_for_city
    Weather::CheckWeatherForCityService.new.query_weather(
      city: params[:city], country: params[:country]
    )['weather_overview']
  end
end
