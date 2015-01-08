require 'rails_helper'
require 'time_range'

describe TimeRange do

	describe 'instance' do
		it 'assigns default value for from 20 days ago' do
			time = TimeRange.new
			expect(time.from).to eq(20.days.ago.to_i)
		end

		it 'assigns default value for to the current time' do
			time = TimeRange.new
			expect(time.to).to eq(Time.now.to_i)
		end

		it 'converts from value from time to integer' do
			time = TimeRange.new(3.days.ago)
			expect(time.from).to eq(3.days.ago.to_i)
		end

		it 'converts to value from time to integer' do
			time = TimeRange.new(nil, 3.days.from_now)
			expect(time.to).to eq(3.days.from_now.to_i)
		end

		it 'assigns specified value if already number to from' do
			time = TimeRange.new(12345)
			expect(time.from).to eq(12345)
		end

		it 'assigns specified value if already number to to' do
			time = TimeRange.new(nil, 12345)
			expect(time.to).to eq(12345)
		end
	end

	describe '#to_query' do
		it 'generates a mongodb query to filter time' do
			time = TimeRange.new(1234, 3456)
			expect(time.to_query('happened_at')).to eq({
				'happened_at' => {'$gte' => 1234, '$lte' => 3456}				
			})
		end
	end

	describe '#append_to_query' do
		it 'appends a time filter to an existing query (hash)' do
			time = TimeRange.new(1234, 3456)
			query = {'name' => 'luiz'}
			time.append_to_query('happened_at', query)
			expect(query).to eq({
				'name' => 'luiz',
				'happened_at' => {'$gte' => 1234, '$lte' => 3456}				
			})
		end
	end
	
end