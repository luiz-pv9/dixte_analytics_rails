require 'rails_helper'
require 'collections'

describe Collections do

	it 'has the properties collection' do
		expect(Collections::Properties.name).to eq(:properties)
		expect(Collections::Properties.collection).to be_truthy
	end

	it 'has the profiles collection' do
		expect(Collections::Profiles.name).to eq(:profiles)
		expect(Collections::Profiles.collection).to be_truthy
	end

	it 'has the apps collection' do
		expect(Collections::Apps.name).to eq(:apps)
		expect(Collections::Apps.collection).to be_truthy
	end

	it 'has the app metrics collection' do
		expect(Collections::AppMetrics.name).to eq(:app_metrics)
		expect(Collections::AppMetrics.collection).to be_truthy
	end

	it 'has the warns collection' do
		expect(Collections::Warns.name).to eq(:warns)
		expect(Collections::Warns.collection).to be_truthy
	end
end