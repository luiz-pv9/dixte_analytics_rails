require 'rails_helper'
require 'data_cleaner'

describe DataCleaner do
	describe '.clean_hash' do
		it 'cleans a hash with the specified values' do
			cleaned = DataCleaner.clean_hash({:name => 'Luiz'}, [:json_string_value])
			expect(cleaned).to eq(:name => 'Luiz')
		end

		it 'deletes the key if the value is not in the specified clean list' do
			cleaned = DataCleaner.clean_hash({:name => 'Luiz', :age => 20}, [:json_string_value])
			expect(cleaned).to eq(:name => 'Luiz')
		end

		it 'matches nested array values' do
			cleaned = DataCleaner.clean_hash({:ages => [10, 20], :age => 20}, [[:json_numeric_value]])
			expect(cleaned).to eq(:ages => [10, 20])
		end

		it 'returns an empty hash if the query is not a hash' do
			expect(DataCleaner.clean_hash('foo', [])).to eq({})
		end

		it 'removes values not specified in the allowed list' do
			allowed = [
				:json_string_value,
				{'$gt' => :json_numeric_value},
				{'$ne' => :json_simple_value},
			]

			query = {'name' => 'Luiz', 'age' => {'$gt' => 20}}
			expect(DataCleaner.clean_hash(query, allowed)).to eq({'name' => 'Luiz', 'age' => {'$gt' => 20}})

			query = {'name' => 'Luiz', 'age' => {'$gt' => 20, '$ne' => 25}}
			expect(DataCleaner.clean_hash(query, allowed)).to eq({'name' => 'Luiz', 'age' => {'$gt' => 20, '$ne' => 25}})

			query = {'name' => 'Luiz', 'age' => {'$gt' => 20, 'foo' => 25}}
			expect(DataCleaner.clean_hash(query, allowed)).to eq({'name' => 'Luiz'})
		end
	end

	describe 'clean_array' do
		it 'returns an empty array if the query is not an array' do
			expect(DataCleaner.clean_array('foo', [])).to eq([])
		end

		it 'removes values not specifie in the allowed list' do
			allowed = [
				:json_string_value,
				{'$gt' => :json_numeric_value},
				{'$ne' => :json_simple_value},
			]
			
			query = [
				{'name' => 'Luiz'},
				{'age' => {'$gt' => 20}}
			]
			expect(DataCleaner.clean_array(query, allowed)).to eq([
				{'name' => 'Luiz'},
				{'age' => {'$gt' => 20}}
			])

			query = [
				{'name' => 'Luiz'},
				{'age' => {'$gt' => 20, 'foo' => 'bar'}},
				{'address' => 'foobar', 'age' => {'$gt' => 20}}
			]
			expect(DataCleaner.clean_array(query, allowed)).to eq([
				{'name' => 'Luiz'},
				{'address' => 'foobar', 'age' => {'$gt' => 20}}
			])
		end
	end
end