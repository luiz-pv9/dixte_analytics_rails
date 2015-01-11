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

	describe 'steps' do
		it 'generates an array of steps in hours' do
			now = Time.now
			time_range = TimeRange.new(now, now + 1.day)
			expect(time_range.steps_in_hours.size).to eq(25)

			time_range = TimeRange.new(now, now + 5.hours)
			expect(time_range.steps_in_hours.size).to eq(6)
		end

		it 'generates an array of steps in days' do
			now = Time.strptime('01/01/2015', '%d/%m/%Y')
			time_range = TimeRange.new(now, now + 11.days)
			expect(time_range.steps_in_days.size).to eq(12)

			now = Time.strptime('20/12/2015', '%d/%m/%Y')
			time_range = TimeRange.new(now, now + 15.days)
			expect(time_range.steps_in_days.size).to eq(16)
		end

		it 'generates an array of steps in weeks' do
			now = Time.strptime('01/01/2015', '%d/%m/%Y')
			time_range = TimeRange.new(now, now + 1.month)
			expect(time_range.steps_in_weeks.size).to eq(5)

			now = Time.strptime('01/01/2015', '%d/%m/%Y')
			time_range = TimeRange.new(now, now + 2.months)
			expect(time_range.steps_in_weeks.size).to eq(9)
		end

		it 'generates an array of steps in months' do
			now = Time.strptime('01/01/2015', '%d/%m/%Y')
			time_range = TimeRange.new(now, now + 5.months)
			expect(time_range.steps_in_months.size).to eq(6)

			now = Time.strptime('01/01/2015', '%d/%m/%Y')
			time_range = TimeRange.new(now, now + 1.year)
			expect(time_range.steps_in_months.size).to eq(13)
		end

		it 'generates an array of steps in trimesters' do
			now = Time.strptime('01/01/2015', '%d/%m/%Y')
			time_range = TimeRange.new(now, now + 1.year)
			expect(time_range.steps_in_trimesters.size).to eq(5)
		end

		it 'generates an array of steps in semesters' do
			now = Time.strptime('01/01/2015', '%d/%m/%Y')
			time_range = TimeRange.new(now, now + 3.years)
			expect(time_range.steps_in_semesters.size).to eq(7)
		end

		it 'generates an array of steps in years' do
			now = Time.strptime('01/01/2015', '%d/%m/%Y')
			time_range = TimeRange.new(now, now + 3.years)
			expect(time_range.steps_in_years.size).to eq(4)
		end
	end	
end