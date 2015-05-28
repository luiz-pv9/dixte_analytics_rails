require 'collections'

class ProfileAliaser
	@@collection = Collections::Profiles.collection

	def update_profile(app_token, previous, current)
		profile = @@collection.find({
			:app_token => app_token,
			:external_id => previous
		})
		profile.update({
			'$set' => {'external_id' => current}
		})
	end

	def update_profile_events(app_token, previous, current)
		events = EventFinder.by_external_id({
			:app_token => app_token,
			:external_id => previous
		})
		events.update_all({
			'$set' => {'external_id' => current}
		})
	end

	def self.perform(opt)
		ProfileAliaser.new().perform(opt)
	end

	def perform(opt)
		opt.symbolize_keys!
		update_profile(opt[:app_token], opt[:previous], opt[:current])
		update_profile_events(opt[:app_token], opt[:previous], opt[:current])
	end
end