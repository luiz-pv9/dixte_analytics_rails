module Collections

	def self.query_to_array(query)
		docs = []
		query.each do |doc|
			docs << doc
		end
		docs
	end

	class CollectionDefinition
		class << self
			def collection
				Mongoid::Sessions.default[name]
			end
		end
	end

	class Properties < CollectionDefinition
		@name = :properties
		Mongoid::Sessions.default[@name].indexes.create({:key => 1}, {:unique => true})
		
		class << self
			attr_reader :name
		end
	end

	class Profiles < CollectionDefinition
		@name = :profiles
		Mongoid::Sessions.default[@name].indexes.create({:app_token => 1, :external_id => 1}, {:unique => true})
		class << self
			attr_reader :name
		end
	end

	class Events < CollectionDefinition
		@name = :events
		Mongoid::Sessions.default[@name].indexes.create({:app_token => 1, :type => 1})
		Mongoid::Sessions.default[@name].indexes.create({:app_token => 1, :external_id => 1})
		class << self
			attr_reader :name
		end
	end

	class Apps < CollectionDefinition
		@name = :apps
		# The token is already indexed by the tokeanble concern
		class << self
			attr_reader :name
		end
	end

	class AppMetrics < CollectionDefinition
		@name = :app_metrics
		class << self
			attr_reader :name
		end
	end

	class Warns < CollectionDefinition
		@name = :warns
		class << self
			attr_reader :name
		end
	end
end
