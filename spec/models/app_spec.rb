require 'rails_helper'
require 'collections'

describe App do
	before :each do
		delete_all
	end

	describe 'required fields' do
		it 'requires a name' do
			app = App.new
			app.save
			expect(app).not_to be_valid

			app = App.new :name => 'Dixte'
			app.save
			expect(app).to be_valid
		end
	end

	describe 'keys of tracking properties' do
		it 'has a key for profile properties' do
			expect(App.profiles_key('foo')).to eq(['foo', 'profiles'])
		end

		it 'has a key for events properties' do
			expect(App.event_types_key('foo')).to eq(['foo', 'event_types'])
		end
	end

	describe 'users ownership' do
	end

	describe 'warns' do
		it 'has many warns' do
			@app = App.create :name => 'Dixte'
			warn = Warn.create(:app => @app, :level => Warn::LOW, :message => 'what')
			expect(@app.warns).to eq([warn])
		end
		it 'removes warns based on creation time'
	end

	describe 'token generation' do
		it 'generates an unique token upon creation' do
			app = App.new :name => 'Dixte'
			app.save
			expect(app.token.length).to eq(22)
		end

		it 'doesnt update the token when updating the app' do
			app = App.create :name => 'Dixte'
			app_token = app.token
			app.update_attributes(:name => 'Liato')
			expect(app.name).to eq('Liato')
			expect(app.token).to eq(app_token)
		end
	end

	describe 'metrics' do
		before :each do
			@event_tracker = EventTracker.new
			@profile_tracker = ProfileTracker.new
		end

		it 'returns all events of the app' do
			app_1 = App.create :name => 'Dixte'
			app_2 = App.create :name => 'Fran'

			@event_tracker.perform({
				'app_token' => app_1.token,
				'external_id' => 'lpvasco',
				'type' => 'click button',
				'properties' => {}
			})
			@event_tracker.perform({
				'app_token' => app_1.token,
				'external_id' => 'luiz',
				'type' => 'click button',
				'properties' => {}
			})
			@event_tracker.perform({
				'app_token' => app_2.token,
				'external_id' => 'fran',
				'type' => 'click button',
				'properties' => {}
			})
			@event_tracker.perform({
				'app_token' => app_1.token,
				'external_id' => 'lpvasco',
				'type' => 'click button',
				'properties' => {}
			})

			expect(app_1.events.count).to eq(3)
			expect(app_2.events.count).to eq(1)
		end

		it 'finds all events that happened in a month' do
			app_1 = App.create :name => 'Dixte'

			@event_tracker.perform({
				'app_token' => app_1.token,
				'external_id' => 'lpvasco',
				'happened_at' => Time.strptime('01/03/2014', '%d/%m/%Y').to_i,
				'type' => 'click button',
				'properties' => {}
			})
			@event_tracker.perform({
				'app_token' => app_1.token,
				'external_id' => 'luiz',
				'happened_at' => Time.strptime('30/03/2014', '%d/%m/%Y').to_i,
				'type' => 'click button',
				'properties' => {}
			})
			@event_tracker.perform({
				'app_token' => app_1.token,
				'happened_at' => Time.strptime('05/04/2014', '%d/%m/%Y').to_i,
				'external_id' => 'lpvasco',
				'type' => 'click button',
				'properties' => {}
			})

			expect(app_1.events_at_month('2014', '03').count).to eq(2)
			expect(app_1.events_at_month('2014', '04').count).to eq(1)
		end

		it 'finds all profiles for the app' do
			app_1 = App.create :name => 'Dixte'
			app_2 = App.create :name => 'Foo'
			@profile_tracker.perform({
				'app_token' => app_1.token,
				'external_id' => 'lpvasco',
				'properties' => {}
			})
			@profile_tracker.perform({
				'app_token' => app_2.token,
				'external_id' => 'lpvasco',
				'properties' => {}
			})
			@profile_tracker.perform({
				'app_token' => app_1.token,
				'external_id' => 'luizpv9',
				'properties' => {}
			})

			expect(app_1.profiles.count).to eq(2)
			expect(app_2.profiles.count).to eq(1)
		end
	end
end