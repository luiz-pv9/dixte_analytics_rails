require 'rails_helper'

describe 'MongoHelper specs' do

	it 'connects to MongoDB and selects the database' do
		expect(MongoHelper.database).to be_truthy
	end

	def load_config_file
		YAML.load_file "#{Rails.root}/config/mongo.yml"
	end

	it 'connects to the host specified in the config file' do
		config = load_config_file()[Rails.env]
		expect(MongoHelper.database.client.host).to eq(config['host'])
	end

	it 'selects the database specified in the config file' do
		config = load_config_file()[Rails.env]
		expect(MongoHelper.database.name).to eq(config['dbname'])
	end
end
