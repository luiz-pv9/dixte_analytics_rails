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

	describe 'appending the profile properties in the events'
	describe 'storing the event'
end