require 'collections'

class ProfileFinder
	@@collection = Collections::Profiles.collection

	class << self
		def by_external_id(external_id)
			@@collection.find(:external_id => external_id).first
		end
	end
end