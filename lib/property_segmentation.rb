class PropertySegmentation
	def initialize(data)
		@data = data
	end

	def segment_by_property(property)
		segmentation = {}
		@data.each do |doc|
			prop = doc['properties'][property]
			segmentation[prop] ||= 0
			segmentation[prop] += 1
		end
		segmentation
	end
end