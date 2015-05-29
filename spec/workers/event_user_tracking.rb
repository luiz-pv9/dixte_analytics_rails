require 'rails_helper'
require 'collections'

describe EventTracker do
	before :each do
		@event_tracker = EventTracker.new
		delete_all
		@app = App.create :name => 'Dixte'
		@user = User.create(:email => 'luiz.pv9@gmail.com', :password => '1234',
			:password_confirmation => '1234')
	end

	it 'tracks the user who created the event in the modified_by array' do
		event = @event_tracker.perform({
			'app_token' => @app.token,
			'external_id' => 'lpvasco',
			'type' => 'event_type',
			'properties' => {}
		}, @user)

		expect(event['modified_by']).to eq([@user.id])
	end

	it 'tracks the user who updated appending to the modified_by array' do
		event = @event_tracker.perform({
			'app_token' => @app.token,
			'external_id' => 'lpvasco',
			'type' => 'event_type',
			'properties' => {}
		}, @user)

		expect(event['modified_by']).to eq([@user.id])

		@event_tracker.perform({
			'_id' => event['_id'],
			'properties' => {}
		}, @user)

		event = EventFinder.by_id(event['_id'])
		expect(event['modified_by']).to eq([@user.id, @user.id])
	end
end