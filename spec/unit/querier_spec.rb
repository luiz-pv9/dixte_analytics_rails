require 'querier'

describe Querier do
	describe 'instance' do
		it 'receives the query in the constructor' do
			query = Querier.new({})
			expect(query).to be_truthy
		end

		it 'has the query accessor reader' do
			query = Querier.new({'a' => 10})
			expect(query.query).to eq({'a' => 10})
		end
	end

	describe 'cleaning the query' do
		describe 'root node' do
			it 'accepts the root class in the config' do
				query = Querier.new([10, 20], {
					:root => Array
				})
				expect(query.clean).to eq([10, 20])

				query = Querier.new([10, 20], {
					:root => Hash
				})
				expect(query.clean).to eq({})
			end
		end

		describe 'looping through the query' do
			it 'loops through the query' do
				query = Querier.new([10, 20], {
					:root => Array
				})
				total = 0
				query.each_array do |val|
					total += val
				end
				expect(total).to eq(30)
			end

			it 'loops through the hash query as an array' do
				query = Querier.new({'a' => 10, 'b' => 20}, {
					:root => Array
				})
				total = 0
				query.each_hash do |val|
					total += val
				end
				expect(total).to eq(30)
			end
		end

		describe 'allowed formats for each filter' do
			before :each do
				@query = Querier.new({}, {
					:root => Hash,
					:multiple_operations => true,
					:allowed => [
						{:key => {'$eq' => :json_simple_value}},
						{:key => {'$ne' => :json_simple_value}},
						{:key => {'$gt' => :json_simple_value}},
					]
				})
			end

			it 'accepts filters in any of the specified format' do
				@query.query = {'name' => {'$eq' => 'Luiz'}}
				clean = @query.clean
				expect(clean).to eq({'name' => {'$eq' => 'Luiz'}})
			end

			it 'removes from the hash operations that are not in the specified allowed list' do
				@query.query = {'name' => {'foo' => 'Luiz'}}
				clean = @query.clean
				# expect(clean).to eq({})
			end
		end
	end
end
