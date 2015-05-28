require 'collections'

# The ProfileUntracker class is responsible for, guess what, untracking profiles. 
# This operation may not be a common thing, since most applications want to keep
# a history of all the users it had, even if they delete their account.
# One option is to just update the profile with a flag (deleted => true), or
# a timestamp (deleted_at => 13132).
# This class must just be called if the application wants to remove the profile
# and all events associated with it PERMANENTLY from the database
class ProfileUntracker
	@@collection = Collections::Profiles.collection

	# Removes all tracked properties stored for the specified profile.
	# Each app has one document for storing properties of it's profiles, and
	# this method makes sure the properties are being properly untracked.
	def untrack_properties(profile)
		if profile['properties'] && profile['properties'].size > 0
			property_untracker = PropertyUntracker.new(
				App.profiles_key(profile['app_token']), profile['properties'])
			property_untracker.untrack!
		end
	end

	# Removes the profile from the database collection
	def remove_profile(profile)
		@@collection.find('_id' => profile['_id']).remove
	end

	# Untracks the profile for the specified app_token and external id.
	# This method calls other methods to remove the properties in the profile
	# and to remove the document itself from the database
	def untrack_profile(app_token, external_id)
		profile = ProfileFinder.by_external_id({
			:app_token => app_token, 
			:external_id => external_id
		})
		if profile
			untrack_properties(profile)
			remove_profile(profile)
			profile
		else
			false
		end
	end

	def enqueue_event_untracking_for_profile(app_token, external_id)
		EventUntracker.perform({
			:app_token => app_token,
			:external_id => external_id
		})
	end

	def enqueue_event_untracking_for_profiles(app_token, external_ids)
		EventUntracker.perform({
			:app_token => app_token,
			:external_ids => external_ids
		})
	end

	# Since this is a Sidekiq::Worker, the perform method is the "entry point"
	# of this class. It may receive two options for untracking a profile:
	# * external_id -> untracks a single profile
	# * external_ids -> untracks multiple profiles
	# But if the application really wants to remove the profile, 
	def perform(opt)
		opt.symbolize_keys!
		if opt[:external_id]
			if untrack_profile(opt[:app_token], opt[:external_id])
				enqueue_event_untracking_for_profile(opt[:app_token], opt[:external_id])
			end
		end

		if opt[:external_ids] 
			opt[:external_ids].each do |external_id| 
				untrack_profile(opt[:app_token], external_id)
			end
			enqueue_event_untracking_for_profiles(opt[:app_token], opt[:external_ids])
		end
	end
end