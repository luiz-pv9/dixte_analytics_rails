require 'querier'

describe Querier do
	it 'instances the class with data and config' do
		querier = Querier.new({}, {})
		expect(querier).to be_truthy
	end

	it 'has accessor for query and config' do
		querier = Querier.new({:a => 10}, {:b => 20})
		expect(querier.query).to eq({:a => 10})
		expect(querier.config).to eq({:b => 20})
		querier.query = {:a => 11}
		querier.config = {:b => 22}
		expect(querier.query).to eq({:a => 11})
		expect(querier.config).to eq({:b => 22})
	end

	describe '.match_value' do
		it 'matches exact string types' do
			expect(Querier.match_value('foo', 'foo')).to be(true)
			expect(Querier.match_value('foo', 'bar')).to be(false)
			expect(Querier.match_value('123', 123)).to be(false)
		end

		it 'matches exact numeric types' do
			expect(Querier.match_value(132, 132)).to be(true)
			expect(Querier.match_value(0.5, 0.5)).to be(true)
			expect(Querier.match_value(0.5, '0.5')).to be(false)
		end

		it 'matches exact boolean types' do
			expect(Querier.match_value(true, true)).to be(true)
			expect(Querier.match_value(false, false)).to be(true)
			expect(Querier.match_value(false, 'false')).to be(false)
		end

		it 'matches any string values' do
			expect(Querier.match_value(:json_string_value, 'foo')).to be(true)
			expect(Querier.match_value(:json_string_value, 'bar')).to be(true)
			expect(Querier.match_value(:json_string_value, 123)).to be(false)
		end

		it 'matches any numeric type' do
			expect(Querier.match_value(:json_numeric_value, 123)).to be(true)
			expect(Querier.match_value(:json_numeric_value, 0.5)).to be(true)
			expect(Querier.match_value(:json_numeric_value, '0.5')).to be(false)
		end

		it 'matches any boolean type' do
			expect(Querier.match_value(:json_boolean_value, true)).to be(true)
			expect(Querier.match_value(:json_boolean_value, false)).to be(true)
			expect(Querier.match_value(:json_boolean_value, 1)).to be(false)
		end

		it 'matches any native json type' do
			expect(Querier.match_value(:json_simple_value, 'foo')).to be_truthy
			expect(Querier.match_value(:json_simple_value, 123)).to be_truthy
			expect(Querier.match_value(:json_simple_value, true)).to be_truthy
			expect(Querier.match_value(:json_simple_value, [])).to be_falsy
		end

		it 'matches hash expressions' do
			match = Querier.match_value(
				{:json_string_value => :json_numeric_value},
				{'foobar' => 20})
			expect(match).to be(true)

			match = Querier.match_value(
				{:json_string_value => :json_numeric_value},
				{'foobar' => 'qux'})
			expect(match).to be(false)

			match = Querier.match_value(
				{'$ne' => :json_simple_value},
				{'$ne' => 'qux'})
			expect(match).to be(true)

			match = Querier.match_value(
				{'$ne' => :json_simple_value},
				{'$q' => 'qux'})
			expect(match).to be(false)
		end

		it 'matches hash expressions recursively' do
			match = Querier.match_value(
				{:json_string_value => {'foo' => :json_numeric_value}},
				{'foobar' => {'foo' => 20}})
			expect(match).to be(true)

			match = Querier.match_value(
				{:json_string_value => {'foo' => :json_numeric_value}},
				{'foobar' => {'qux' => 20}})
			expect(match).to be(false)
		end

		it 'matches array expressions' do
			match = Querier.match_value([:json_numeric_value], [10, 20, 30])
			expect(match).to be(true)

			match = Querier.match_value([:json_numeric_value], [10, 20, 30, '5'])
			expect(match).to be(false)

			match = Querier.match_value([:json_numeric_value, true], [10, 20, true, 30])
			expect(match).to be(true)

			match = Querier.match_value([:json_numeric_value, true], [10, 20, false, 30])
			expect(match).to be(false)
		end
	end

	describe 'HashQuerier' do
		describe 'cleaning' do
			before :each do
				@query = HashQuerier.new({}, {
					:multiple_operations => true,
					:allowed => [
						:json_string_value,
						{'$eq' => :json_simple_value},
						{'$ne' => :json_simple_value},
						{'$gt' => :json_numeric_value}
					]
				})
			end

			it 'returns an empty hash if the query is not a hash' do
				@query.query = 10
				expect(@query.clean).to eq({})
			end

			it 'removes values not specified in the allowed list' do
				@query.query = {'name' => 'Luiz', 'age' => {'$gt' => 20}}
				expect(@query.clean).to eq({'name' => 'Luiz', 'age' => {'$gt' => 20}})
			end
		end
	end

	describe 'ArrayQuerier' do
	end
end
