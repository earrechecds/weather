# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Home Page' do
  let(:home_page) { HomePage.new }
  let(:api_mocker) { WeatherMocker.new }
  let(:latitude) { '-34.901112' }
  let(:longitude) { '-56.164532' }
  let(:response_api) { 'The current weather is super nice' }

  feature 'getting the weather for current location' do
    subject { home_page.visit_home_page }

    context 'when the location is not permitted' do
      scenario 'shows button for refreshing the weather after permission is given' do
        subject

        expect(home_page).to have_refresh_button
      end
    end

    context 'when the location is permitted', :js do
      before do
        api_mocker.mock_query_by_position_with_success(latitude: latitude, longitude: longitude)
      end

      scenario 'shows button for refreshing the weather after permission is given' do
        subject

        expect(home_page).to have_weather(response_api)
        expect(home_page).not_to have_refresh_button
      end
    end
  end

  feature 'getting the weather for a selected city', :js do
    subject { home_page.visit_home_page }

    let(:city) { 'Centro' }
    let(:state) { 'Montevideo Department' }
    let(:country) { 'Uruguay' }
    let(:country_code) { 'UY' }

    before do
      api_mocker.mock_query_position_for_city_with_success(city: city, country: country_code)
      api_mocker.mock_query_by_position_with_success(latitude: latitude, longitude: longitude)
    end

    scenario 'shows button for refreshing the weather after permission is given' do
      subject

      home_page.fill_location(country, state, city)
      home_page.click_get_weather_for_city

      expect(home_page).to have_city_weather(response_api)
    end
  end
end
