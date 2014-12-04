require 'mongo'

# Static class to store the database being used in the app.
# Connection pooling is handled by the driver, so don't need to worry.
class MongoHelper
	class << self
		attr_accessor :database
	end
end

# Load config file
mongo_config = YAML.load_file "#{Rails.root}/config/mongo.yml"

# Get environment credentials
env_config = mongo_config[Rails.env]

# Connects to MongoDB
client = Mongo::MongoClient.new env_config['host'], env_config['port']

# Stores the database in the MongoHelper in order for it to be accessable
# across all models
MongoHelper.database = client.db env_config['dbname']
