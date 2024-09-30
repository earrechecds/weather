# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Weather::ApiClientService do
  let(:api_mocker) { WeatherMocker.new }
  let(:latitude_from_uruguay) { -34.901112 }
  let(:longitude_from_uruguay) { -56.164532 }
  let(:latitude) { latitude_from_uruguay }
  let(:longitude) { longitude_from_uruguay }
  let(:response_description) { 'broken clouds' }

  describe '#query_by_position' do
    subject { described_class.new.query_by_position(latitude: latitude, longitude: longitude) }

    context 'when a parameter is missing' do
      let(:latitude_is_missing) { [true, false].sample }
      let(:latitude) { latitude_is_missing ? [nil, ''].sample : latitude_from_uruguay }
      let(:longitude) { latitude_is_missing ? longitude_from_uruguay : [nil, ''].sample }

      it { expect { subject }.to raise_error(ArgumentError) }
    end

    context 'when a valid place is given' do
      before do
        api_mocker.mock_query_by_position_with_success(latitude: latitude, longitude: longitude)
      end

      it 'returns the parsed response' do
        expect(subject.dig('current', 'weather', 0, 'description')).to eq(response_description)
      end
    end

    context 'when an invalid place is given' do
      let(:latitude) { 999 }
      let(:error_message) do
        "Could not retrieve weather for [latitude: #{latitude}, longitude #{longitude}}]. " \
          'Details: The valid range of latitude in degrees is -90 and +90. Check parameter/s: lat'
      end

      before do
        api_mocker.mock_query_by_position_with_lat_out_of_range(
          latitude: latitude, longitude: longitude
        )
      end

      it { expect { subject }.to raise_error(Weather::Error, error_message) }
    end
  end

  describe '#query_position_for_city' do
    subject { described_class.new.query_position_for_city(city: city, country: country) }

    context 'when a parameter is missing' do
      let(:city_is_missing) { [true, false].sample }
      let(:city) { city_is_missing ? [nil, ''].sample : 'Montevideo' }
      let(:country) { city_is_missing ? 'UY' : [nil, ''].sample }

      it { expect { subject }.to raise_error(ArgumentError) }
    end

    context 'when sending a valid city and country' do
      let(:city) { 'Montevideo' }
      let(:country) { 'Uruguay' }

      before { api_mocker.mock_query_position_for_city_with_success(city: city, country: country) }

      it 'returns the parsed response' do
        expect(subject.first['lat']).to eq(latitude_from_uruguay)
        expect(subject.first['lon']).to eq(longitude_from_uruguay)
      end
    end

    context 'when an invalid place is given' do
      let(:city) { 'UnknownCity' }
      let(:country) { 'Uruguay' }
      let(:error_message) { "Unknown city #{city} and country #{country}" }

      before do
        api_mocker.mock_query_position_for_city_with_no_result(city: city, country: country)
      end

      it { expect { subject }.to raise_error(Weather::Error, error_message) }
    end
  end
end
