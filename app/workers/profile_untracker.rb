require 'collections'

class ProfileUntracker
	include Sidekiq::Worker
	@@collection = Collections::Profiles.collection

	def untrack_properties(profile)
		if profile['properties'] && profile['properties'].size > 0
			property_untracker = PropertyUntracker.new(
				App.profile_properties_key(profile['app_token']), profile['properties'])
			property_untracker.untrack!
		end
	end

	def remove_profile(profile)
		@@collection.find('_id' => profile['_id']).remove
	end

	def untrack_profile(app_token, external_id)
		profile = ProfileFinder.by_external_id({
			:app_token => app_token, 
			:external_id => external_id
		})
		if profile
			untrack_properties(profile)
			remove_profile(profile)
		end
	end

	def perform(app_token, external_id)
		if external_id.is_a?(Array)
			external_id.each do |e_external_id|
				untrack_profile(app_token, e_external_id)
			end
		else
			untrack_profile(app_token, external_id)
		end
	end
end