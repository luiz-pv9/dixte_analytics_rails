require 'rails_helper'
require 'json_matcher'

describe JSONMatcher do
	describe '.match_value' do
		it 'matches exact string types' do
			expect(JSONMatcher.matches('foo', 'foo')).to be(true)
			expect(JSONMatcher.matches('foo', 'bar')).to be(false)
			expect(JSONMatcher.matches('123', 123)).to be(false)
		end

		it 'matches exact numeric types' do
			expect(JSONMatcher.matches(132, 132)).to be(true)
			expect(JSONMatcher.matches(0.5, 0.5)).to be(true)
			expect(JSONMatcher.matches(0.5, '0.5')).to be(false)
		end

		it 'matches exact boolean types' do
			expect(JSONMatcher.matches(true, true)).to be(true)
			expect(JSONMatcher.matches(false, false)).to be(true)
			expect(JSONMatcher.matches(false, 'false')).to be(false)
		end

		it 'matches any string values' do
			expect(JSONMatcher.matches(:json_string_value, 'foo')).to be(true)
			expect(JSONMatcher.matches(:json_string_value, 'bar')).to be(true)
			expect(JSONMatcher.matches(:json_string_value, 123)).to be(false)
		end

		it 'matches any numeric type' do
			expect(JSONMatcher.matches(:json_numeric_value, 123)).to be(true)
			expect(JSONMatcher.matches(:json_numeric_value, 0.5)).to be(true)
			expect(JSONMatcher.matches(:json_numeric_value, '0.5')).to be(false)
		end

		it 'matches any boolean type' do
			expect(JSONMatcher.matches(:json_boolean_value, true)).to be(true)
			expect(JSONMatcher.matches(:json_boolean_value, false)).to be(true)
			expect(JSONMatcher.matches(:json_boolean_value, 1)).to be(false)
		end

		it 'matches any native json type' do
			expect(JSONMatcher.matches(:json_simple_value, 'foo')).to be_truthy
			expect(JSONMatcher.matches(:json_simple_value, 123)).to be_truthy
			expect(JSONMatcher.matches(:json_simple_value, true)).to be_truthy
			expect(JSONMatcher.matches(:json_simple_value, [])).to be_falsy
		end

		it 'matches hash expressions' do
			match = JSONMatcher.matches(
				{:json_string_value => :json_numeric_value},
				{'foobar' => 20})
			expect(match).to be(true)

			match = JSONMatcher.matches(
				{:json_string_value => :json_numeric_value},
				{'foobar' => 'qux'})
			expect(match).to be(false)

			match = JSONMatcher.matches(
				{'$ne' => :json_simple_value},
				{'$ne' => 'qux'})
			expect(match).to be(true)

			match = JSONMatcher.matches(
				{'$ne' => :json_simple_value},
				{'$q' => 'qux'})
			expect(match).to be(false)
		end

		it 'matches hash expressions recursively' do
			match = JSONMatcher.matches(
				{:json_string_value => {'foo' => :json_numeric_value}},
				{'foobar' => {'foo' => 20}})
			expect(match).to be(true)

			match = JSONMatcher.matches(
				{:json_string_value => {'foo' => :json_numeric_value}},
				{'foobar' => {'qux' => 20}})
			expect(match).to be(false)
		end

		it 'matches array expressions' do
			match = JSONMatcher.matches([:json_numeric_value], [10, 20, 30])
			expect(match).to be(true)

			match = JSONMatcher.matches([:json_numeric_value], [10, 20, 30, '5'])
			expect(match).to be(false)

			match = JSONMatcher.matches([:json_numeric_value, true], [10, 20, true, 30])
			expect(match).to be(true)

			match = JSONMatcher.matches([:json_numeric_value, true], [10, 20, false, 30])
			expect(match).to be(false)
		end
	end
end