require 'rails_helper'
require 'collections'

describe EventTracker do

	def valid_app
		App.create :name => 'Dixte'
	end

	def valid_app_token
		valid_app.token
	end

	before :each do
		@event_tracker = EventTracker.new
		@profile_tracker = ProfileTracker.new
		App.delete_all
		Warn.delete_all
		@profiles = Collections::Profiles.collection
		@events = Collections::Events.collection
		@properties = Collections::Properties.collection

		@profiles.find().remove_all
		@properties.find().remove_all
		@events.find().remove_all
	end

	it 'returns -1 if the app token is not present in the data' do
		expect(@event_tracker.perform({'foo' => 'bar'})).to eq(-1)
	end

	describe 'warning generation on bad formatted events' do
		it 'generates a warn if the properties hash is not present in the data' do
			app = valid_app
			expect {
				@event_tracker.perform({'app_token' => app.token, 'external_id' => 'lpvasco'})
			}.to change { Warn.all.count }.by(1)
			warn = Warn.first
			expect(warn.level).to eq(Warn::MEDIUM)
			expect(warn.app).to eq(app)
			expect(warn.data).to eq({
				'app_token' => app.token,
				'external_id' => 'lpvasco'
			})
		end

		it 'generates a warn if the external_id is not present in the data' do
			app = valid_app
			expect {
				@event_tracker.perform({'app_token' => app.token, 'properties' => {}})
			}.to change { Warn.all.count }.by(1)
			warn = Warn.first
			expect(warn.level).to eq(Warn::MEDIUM)
			expect(warn.app).to eq(app)
			expect(warn.data).to eq({
				'app_token' => app.token,
				'properties' => {}
			})
		end

		it 'generates a warn if any root property were removed in the cleaning process' do
			app = valid_app
			expect {
				@event_tracker.perform({
					'app_token' => app.token,
					'external_id' => 2015,
					'properties' => {}
				})
			}.to change { Warn.all.count }.by(1)
			warn = Warn.first
			expect(warn.level).to eq(Warn::MEDIUM)
			expect(warn.app).to eq(app)
			expect(warn.data).to eq({
				'app_token' => app.token,
				'external_id' => 2015,
				'properties' => {}
			})
		end

		it 'generates a warn if the type is not present in the data' do
			app = valid_app
			expect {
				@event_tracker.perform({'app_token' => app.token, 'properties' => {}, 'external_id' => 'lpvasco'})
			}.to change { Warn.all.count }.by(1)
			warn = Warn.first
			expect(warn.level).to eq(Warn::MEDIUM)
			expect(warn.app).to eq(app)
			expect(warn.data).to eq({
				'app_token' => app.token,
				'external_id' => 'lpvasco',
				'properties' => {}
			})
		end

		it 'generates a warn if the properties has invalid attributes' do
			app = valid_app
			expect {
				@event_tracker.perform({
					'app_token' => app.token,
					'external_id' => 'lpvasco',
					'type' => 'event',
					'properties' => {
						'name' => 'Luiz Paulo',
						'age' => {'foo' => 'bar'}
					}
				})
			}.to change { Warn.all.count }.by(1)
			warn = Warn.first
			expect(warn.level).to eq(Warn::MEDIUM)
			expect(warn.app).to eq(app)
			expect(warn.data).to eq({
				'app_token' => app.token,
				'external_id' => 'lpvasco',
				'type' => 'event',
				'properties' => {
					'name' => 'Luiz Paulo',
					'age' => {'foo' => 'bar'}
				}
			})
		end
	end

	describe 'storing the event' do
		it 'stores the event if all attributes are fine' do
			app = valid_app
			expect {
				@event_tracker.perform({
					'app_token' => app.token,
					'external_id' => 'lpvasco',
					'type' => 'register',
					'properties' => {
						'name' => 'Luiz Paulo',
						'age' => 20
					}
				})
			}.to change { @events.find.count }.by(1)
		end

		it 'may receive happened_at in the data' do
			app = valid_app
			expect {
				@event_tracker.perform({
					'app_token' => app.token,
					'external_id' => 'lpvasco',
					'happened_at' => 12345,
					'type' => 'register',
					'properties' => {
						'name' => 'Luiz Paulo',
						'age' => 20
					}
				})
			}.to change { @events.find.count }.by(1)
			event = @events.find.first
			expect(event['happened_at']).to eq(12345)
		end
	end

	describe 'property tracking' do
		it 'tracks all properties specified in the properties hash' do
			app = valid_app
			expect {
				@event_tracker.perform({
					'app_token' => app.token,
					'external_id' => 'lpvasco',
					'type' => 'register',
					'properties' => {
						'name' => 'Luiz Paulo'
					}
				})
			}.to change { @properties.find.count }.by(1)
			property = @properties.find.first
			expect(property).to eq({
				'_id' => property['_id'],
				'key' => app.token + '#register',
				'properties' => {
					'name' => {
						'type' => 'string',
						'values' => {
							'Luiz Paulo' => 1
						}
					}
				}
			})
		end
	end

	describe 'appending the profile properties in the events' do
		it 'appends the properties in the profile to the event with the acc:prefix' do
			app = valid_app
			@profile_tracker.perform({
				'app_token' => app.token,
				'external_id' => 'lpvasco',
				'properties' => {
					'name' => 'Luiz Paulo',
					'colors' => ['red', 'blue']
				}
			})
			@event_tracker.perform({
				'app_token' => app.token,
				'external_id' => 'lpvasco',
				'type' => 'click',
				'properties' => {
					'label' => 'Help'
				}
			})

			event = @events.find.first
			expect(event.except('_id', 'happened_at')).to eq({
				'app_token' => app.token,
				'type' => 'click',
				'external_id' => 'lpvasco',
				'properties' => {
					'label' => 'Help',
					'acc:name' => 'Luiz Paulo',
					'acc:colors' => ['red', 'blue']
				}
			})
		end
	end

	describe 'registering the event type for the application' do
	end
end