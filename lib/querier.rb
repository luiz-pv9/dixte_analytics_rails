# The Querier class is responsible for cleaning a query with any 
# format
class Querier
	attr_accessor :query, :config

	def initialize(query, config = {})
		@config = config
		@query = query
	end

	def clean
		cleaned = clean_root
		# `e` can be the index if the query is an array or
		# the key if the query is a hash
		each do |val, e|
		end
		cleaned
	end

	def clean_root
		return @query if @query.is_a? @config[:root]
		return @config[:root].new
	end

	def each_array(s_query = @query, &block)
		s_query.each(&block)
	end

	def each_hash(s_query = @query, &block)
		s_query.each do |key, val|
			block.call val, key
		end
	end

	def each(s_query = @query, &block)
		if @query.is_a? Array
			each_array s_query, &block
		elsif @query.is_a? Hash
			each_hash s_query, &block
		end
	end
end
