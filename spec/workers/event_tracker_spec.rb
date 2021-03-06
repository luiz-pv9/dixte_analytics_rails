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
		@profiles = Collections::Profiles.collection
		@events = Collections::Events.collection
		@properties = Collections::Properties.collection

		delete_all
	end

	it 'returns false if the app token is not present in the data' do
		expect(@event_tracker.perform({'foo' => 'bar'})).to eq(false)
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
			@event_tracker.perform({
				'app_token' => app.token,
				'external_id' => 'lpvasco',
				'type' => 'register',
				'properties' => {
					'name' => 'Luiz Paulo'
				}
			})
			properties = Collections.query_to_array(@properties.find)
			property = properties[0]['key'] == app.token + '#register' ? properties[0] : properties[1]
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
		it 'tracks the event type when registering an event' do
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
			}.to change { @properties.find.count }.by(2)

			properties = Collections.query_to_array(@properties.find)
			property = (properties[0]['key'] == app.token + '#event_types') ? properties[0] : properties[1]
			expect(property.except('_id')).to eq({
				'key' => app.token + '#event_types',
				'properties' => {
					'type' => {
						'type' => 'string',
						'values' => {
							'register' => 1
						}
					}
				}
			})
		end

		it 'increments the counter when registering another event of the same type' do
			app = valid_app
			@event_tracker.perform({
				'app_token' => app.token,
				'external_id' => 'lpvasco',
				'type' => 'register',
				'properties' => {
					'name' => 'Luiz Paulo',
					'age' => 20
				}
			})
			@event_tracker.perform({
				'app_token' => app.token,
				'external_id' => 'luiz',
				'type' => 'register',
				'properties' => {
					'name' => 'Luiz Paulo',
					'age' => 20
				}
			})
			properties = Collections.query_to_array(@properties.find)
			property = (properties[0]['key'] == app.token + '#event_types') ? properties[0] : properties[1]
			expect(property.except('_id')).to eq({
				'key' => app.token + '#event_types',
				'properties' => {
					'type' => {
						'type' => 'string',
						'values' => {
							'register' => 2
						}
					}
				}
			})
		end
	end

	describe 'updating an event' do
		it 'updates the event properties hash' do
			app = valid_app
			event = @event_tracker.perform({
				'app_token' => app.token,
				'external_id' => 'lpvasco',
				'type' => 'anything',
				'properties' => {
					'name' => 'Luiz',
					'age' => 20
				}
			})

			expect(event['_id']).to be_truthy

			@event_tracker.perform({
				'_id' => event['_id'],
				'properties' => {
					'age' => 21
				}
			})

			event = EventFinder.by_id(event['_id'])
			expect(event['properties']).to eq({
				'name' => 'Luiz',
				'age' => 21
			})
		end

		it 'updates the tracked properties for the event' do
			app = valid_app
			event = @event_tracker.perform({
				'app_token' => app.token,
				'external_id' => 'lpvasco',
				'type' => 'anything',
				'properties' => {
					'name' => 'Luiz',
					'age' => 20
				}
			})
			expect(event['_id']).to be_truthy
			@event_tracker.perform({
				'_id' => event['_id'],
				'properties' => {
					'age' => 21
				}
			})
			property = Property.new(PropertyFinder.event(app.token, 'anything'))
			expect(property.value_count('name', 'Luiz')).to eq(1)
			expect(property.value_count('age', '20')).to eq(0)
			expect(property.value_count('age', '21')).to eq(1)
		end

		it 'updates the array properties in the event' do
			app = valid_app
			event = @event_tracker.perform({
				'app_token' => app.token,
				'external_id' => 'lpvasco',
				'type' => 'anything',
				'properties' => {
					'colors' => ['red', 'green'],
					'age' => 20
				}
			})
			expect(event['_id']).to be_truthy
			@event_tracker.perform({
				'_id' => event['_id'],
				'properties' => {
					'colors' => ['red', 'blue']
				}
			})

			property = Property.new(PropertyFinder.event(app.token, 'anything'))
			expect(property.value_count('age', '20')).to eq(1)
			expect(property.number_of_values('colors')).to eq(2)
			expect(property.value_count('colors', 'red')).to eq(1)
			expect(property.value_count('colors', 'blue')).to eq(1)
			expect(property.value_count('colors', 'green')).to eq(0)
		end
	end
end