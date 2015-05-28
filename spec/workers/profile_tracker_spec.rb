require 'rails_helper'
require 'collections'

describe ProfileTracker do

	def valid_app
		App.create :name => 'Dixte'
	end

	def valid_app_token
		valid_app.token
	end

	before :each do
		App.delete_all
		Warn.delete_all
		@profile_tracker = ProfileTracker.new
		@profiles = Collections::Profiles.collection
		@properties = Collections::Properties.collection
		@profiles.find().remove_all
		@properties.find().remove_all
		Property.max_properties = 50
	end

	it 'returns false if the app_token is not present in the data' do
		expect(@profile_tracker.perform({'foo' => 'bar'})).to be(false)
	end

	describe 'warning generation on bad formatted profiles' do
		it 'generates a warn if the properties hash is not present in the data' do
			app = valid_app
			expect {
				@profile_tracker.perform({'app_token' => app.token, 'external_id' => 'lpvasco'})
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
				@profile_tracker.perform({'app_token' => app.token, 'properties' => {}})
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
				@profile_tracker.perform({
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

		it 'generates a warn if the properties has invalid attributes' do
			app = valid_app
			expect {
				@profile_tracker.perform({
					'app_token' => app.token,
					'external_id' => 'lpvasco',
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
				'properties' => {
					'name' => 'Luiz Paulo',
					'age' => {'foo' => 'bar'}
				}
			})
		end
	end

	describe 'storing the profile' do
		it 'sets created_at and updated_at when creating the profile' do
			profile = nil
			expect {
				profile = @profile_tracker.perform({
					'app_token' => valid_app_token,
					'external_id' => 'lpvasco',
					'properties' => {
						'name' => 'Luiz Paulo'
					}
				})
			}.to change { @profiles.find.count }.by(1)
			expect(profile['_id']).to be_truthy
			expect(profile['external_id']).to eq('lpvasco')
			expect(profile['properties']).to eq({'name' => 'Luiz Paulo'})
			expect(profile['created_at']).to be_truthy
			expect(profile['updated_at']).to eq(profile['created_at'])
		end

		it 'may receive created_at and updated_at in the hash to override default ones' do
			profile = nil
			expect {
				profile = @profile_tracker.perform({
					'app_token' => valid_app_token,
					'external_id' => 'lpvasco',
					'created_at' => 123456,
					'properties' => {
						'name' => 'Luiz Paulo'
					}
				})
			}.to change { @profiles.find.count }.by(1)
			expect(profile['_id']).to be_truthy
			expect(profile['external_id']).to eq('lpvasco')
			expect(profile['properties']).to eq({'name' => 'Luiz Paulo'})
			expect(profile['created_at']).to eq(123456)
			expect(profile['updated_at']).to eq(123456)
		end

		it 'updates updated_at when updating the profile' do
			app_token = valid_app_token
			@profile_tracker.perform({
				'app_token' => app_token,
				'external_id' => 'lpvasco',
				'created_at' => 123456,
				'properties' => {
					'name' => 'Luiz Paulo'
				}
			})
			profile = nil
			expect {
				profile = @profile_tracker.perform({
					'app_token' => app_token,
					'external_id' => 'lpvasco',
					'properties' => {
						'name' => 'Luiz Paulo'
					}
				})
			}.to change { @profiles.find.count }.by(0)
			profile = @profiles.find.first
			expect(profile['created_at']).to eq(123456)
			expect(profile['updated_at']).not_to eq(123456)
		end

		it 'increments a value with the special increment attribute' do
			app_token = valid_app_token
			@profile_tracker.perform({
				'app_token' => app_token,
				'external_id' => 'lpvasco',
				'created_at' => 123456,
				'properties' => {
					'name' => 'Luiz Paulo',
					'visit_count' => 2
				}
			})
			@profile_tracker.perform({
				'app_token' => app_token,
				'external_id' => 'lpvasco',
				'properties' => {
					'$inc.visit_count' => 3
				}
			})
			profile = @profiles.find.first
			expect(profile['properties']['visit_count']).to eq(5)
		end

		it 'creates the value with the increment operation if no value is found' do
			app_token = valid_app_token
			@profile_tracker.perform({
				'app_token' => app_token,
				'external_id' => 'lpvasco',
				'created_at' => 123456,
				'properties' => {
					'name' => 'Luiz Paulo'
				}
			})
			@profile_tracker.perform({
				'app_token' => app_token,
				'external_id' => 'lpvasco',
				'properties' => {
					'$inc.Visit Count' => 3
				}
			})
			profile = @profiles.find.first
			expect(profile['properties']['Visit Count']).to eq(3)
		end

		it 'appends a value to a list with the special append atttribute' do
			app_token = valid_app_token
			@profile_tracker.perform({
				'app_token' => app_token,
				'external_id' => 'lpvasco',
				'created_at' => 123456,
				'properties' => {
					'name' => 'Luiz Paulo',
					'colors' => ['red', 'blue']
				}
			})
			@profile_tracker.perform({
				'app_token' => app_token,
				'external_id' => 'lpvasco',
				'properties' => {
					'$push.colors' => 'yellow'
				}
			})
			profile = @profiles.find.first
			expect(profile['properties']['colors']).to eq(['red', 'blue', 'yellow'])
		end

		it 'creates the list with the append operation if no list is found' do
			app_token = valid_app_token
			@profile_tracker.perform({
				'app_token' => app_token,
				'external_id' => 'lpvasco',
				'created_at' => 123456,
				'properties' => {
					'name' => 'Luiz Paulo'
				}
			})
			@profile_tracker.perform({
				'app_token' => app_token,
				'external_id' => 'lpvasco',
				'properties' => {
					'$push.colors' => 'yellow'
				}
			})
			profile = @profiles.find.first
			expect(profile['properties']['colors']).to eq(['yellow'])
		end

		it 'removes a value from a list using the $pull operator' do
			app_token = valid_app_token
			@profile_tracker.perform({
				'app_token' => app_token,
				'external_id' => 'lpvasco',
				'created_at' => 123456,
				'properties' => {
					'name' => 'Luiz Paulo',
					'colors' => ['red', 'blue']
				}
			})
			@profile_tracker.perform({
				'app_token' => app_token,
				'external_id' => 'lpvasco',
				'properties' => {
					'$pull.colors' => 'red'
				}
			})
			profile = @profiles.find.first
			expect(profile['properties']['colors']).to eq(['blue'])
		end

		it 'removes a property if the specified value is null' do
			app_token = valid_app_token
			@profile_tracker.perform({
				'app_token' => app_token,
				'external_id' => 'lpvasco',
				'created_at' => 123456,
				'properties' => {
					'name' => 'Luiz Paulo',
					'colors' => ['red', 'blue']
				}
			})
			@profile_tracker.perform({
				'app_token' => app_token,
				'external_id' => 'lpvasco',
				'properties' => {
					'colors' => nil
				}
			})
			profile = @profiles.find.first
			expect(profile['properties']['colors']).to be_nil
		end

		it 'acceps profiles with empty properties hash' do
			profile = nil
			expect {
				@profile_tracker.perform({
					'app_token' => valid_app_token,
					'external_id' => 'lpvasco',
					'properties' => {}
				})
				@profile_tracker.perform({
					'app_token' => valid_app_token,
					'external_id' => 'luiz',
					'properties' => {}
				})
			}.to change { @profiles.find.count }.by(2)
		end

		it 'generates a warn if the value specified in $inc is not numeric' do
			app_token = valid_app_token
			@profile_tracker.perform({
				'app_token' => app_token,
				'external_id' => 'lpvasco',
				'created_at' => 123456,
				'properties' => {
					'name' => 'Luiz Paulo',
					'visit_count' => 2
				}
			})
			expect {
				@profile_tracker.perform({
					'app_token' => app_token,
					'external_id' => 'lpvasco',
					'properties' => {
						'$inc.visit_count' => '3'
					}
				})
			}.to change { Warn.all.count }.by(1)
		end

		it 'has a custom message on the warn if the $inc is not numeric' do
			app_token = valid_app_token
			@profile_tracker.perform({
				'app_token' => app_token,
				'external_id' => 'lpvasco',
				'created_at' => 123456,
				'properties' => {
					'name' => 'Luiz Paulo',
					'visit_count' => 2
				}
			})
			@profile_tracker.perform({
				'app_token' => app_token,
				'external_id' => 'lpvasco',
				'properties' => {
					'$inc.visit_count' => '3'
				}
			})
			expect(Warn.last.message.index('$inc')).not_to be_nil
		end

		it 'generates a warn if the value specified in $pull is not a string' do
			app_token = valid_app_token
			@profile_tracker.perform({
				'app_token' => app_token,
				'external_id' => 'lpvasco',
				'created_at' => 123456,
				'properties' => {
					'name' => 'Luiz Paulo',
					'colors' => ['red', 'blue']
				}
			})
			expect {
				@profile_tracker.perform({
					'app_token' => app_token,
					'external_id' => 'lpvasco',
					'properties' => {
						'$pull.colors' => true
					}
				})
			}.to change { Warn.all.count }.by(1)
		end

		it 'generates a warn if the value specified in $push is not a string' do
			app_token = valid_app_token
			@profile_tracker.perform({
				'app_token' => app_token,
				'external_id' => 'lpvasco',
				'created_at' => 123456,
				'properties' => {
					'name' => 'Luiz Paulo',
					'colors' => ['red', 'blue']
				}
			})
			expect {
				@profile_tracker.perform({
					'app_token' => app_token,
					'external_id' => 'lpvasco',
					'properties' => {
						'$push.colors' => 3
					}
				})
			}.to change { Warn.all.count }.by(1)
		end

		it 'has a custom message on the warn if the $pull or $push value is not a string' do
			app_token = valid_app_token
			@profile_tracker.perform({
				'app_token' => app_token,
				'external_id' => 'lpvasco',
				'created_at' => 123456,
				'properties' => {
					'name' => 'Luiz Paulo',
					'colors' => ['red', 'blue']
				}
			})
			@profile_tracker.perform({
				'app_token' => app_token,
				'external_id' => 'lpvasco',
				'properties' => {
					'$push.colors' => 3
				}
			})
			expect(Warn.last.message.index('$push')).not_to be_nil
			expect(Warn.last.message.index('$pull')).not_to be_nil
		end
	end

	describe 'tracking properties (PropertyTracker usage)' do
		it 'tracks all properties when creating the profile' do
			app_token = valid_app_token
			expect {
				@profile_tracker.perform({
					'app_token' => app_token,
					'external_id' => 'lpvasco',
					'created_at' => 123456,
					'properties' => {
						'name' => 'Luiz Paulo',
						'age' => 21,
						'colors' => ['red', 'blue']
					}
				})
			}.to change { @properties.find.count }.by(1)
			property = @properties.find.first
			expect(property).to eq({
				'_id' => property['_id'],
				'key' => app_token + '#profiles',
				'properties' => {
					'name' => {
						'type' => 'string',
						'values' => {
							'Luiz Paulo' => 1
						}
					},
					'age' => {
						'type' => 'number',
						'values' => {
							'21' => 1
						}
					},
					'colors' => {
						'type' => 'array',
						'values' => {
							'red' => 1,
							'blue' => 1
						}
					}
				}
			})
		end

		it 'untrack previous value and track new one when updating a value' do
			app_token = valid_app_token
			@profile_tracker.perform({
				'app_token' => app_token,
				'external_id' => 'lpvasco',
				'created_at' => 123456,
				'properties' => {
					'name' => 'Luiz Paulo'
				}
			})
			@profile_tracker.perform({
				'app_token' => app_token,
				'external_id' => 'lpvasco',
				'created_at' => 123456,
				'properties' => {
					'name' => 'Luiz Paulo Vasconcellos'
				}
			})

			property = @properties.find.first
			expect(property).to eq({
				'_id' => property['_id'],
				'key' => app_token + '#profiles',
				'properties' => {
					'name' => {
						'type' => 'string',
						'values' => {
							'Luiz Paulo Vasconcellos' => 1
						}
					}
				}
			})
		end

		it 'untrack previous value when removing the previous' do
			app_token = valid_app_token
			@profile_tracker.perform({
				'app_token' => app_token,
				'external_id' => 'lpvasco',
				'created_at' => 123456,
				'properties' => {
					'name' => 'Luiz Paulo',
					'age' => 20
				}
			})
			@profile_tracker.perform({
				'app_token' => app_token,
				'external_id' => 'lpvasco',
				'created_at' => 123456,
				'properties' => {
					'age' => nil
				}
			})

			property = @properties.find.first
			expect(property).to eq({
				'_id' => property['_id'],
				'key' => app_token + '#profiles',
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

		it 'tracks a new value when pushing a new value to the array' do
			app_token = valid_app_token
			@profile_tracker.perform({
				'app_token' => app_token,
				'external_id' => 'lpvasco',
				'created_at' => 123456,
				'properties' => {
					'colors' => ['red', 'blue']
				}
			})
			@profile_tracker.perform({
				'app_token' => app_token,
				'external_id' => 'lpvasco',
				'created_at' => 123456,
				'properties' => {
					'$push.colors' => 'yellow'
				}
			})
			property = @properties.find.first
			expect(property).to eq({
				'_id' => property['_id'],
				'key' => app_token + '#profiles',
				'properties' => {
					'colors' => {
						'type' => 'array',
						'values' => {
							'red' => 1,
							'blue' => 1,
							'yellow' => 1
						}
					}
				}
			})
		end

		it 'untrack values when pulling from array of values' do
			app_token = valid_app_token
			@profile_tracker.perform({
				'app_token' => app_token,
				'external_id' => 'lpvasco',
				'created_at' => 123456,
				'properties' => {
					'colors' => ['red', 'blue']
				}
			})
			@profile_tracker.perform({
				'app_token' => app_token,
				'external_id' => 'lpvasco',
				'created_at' => 123456,
				'properties' => {
					'$pull.colors' => 'blue'
				}
			})
			property = @properties.find.first
			expect(property).to eq({
				'_id' => property['_id'],
				'key' => app_token + '#profiles',
				'properties' => {
					'colors' => {
						'type' => 'array',
						'values' => {
							'red' => 1
						}
					}
				}
			})
		end

		it 'tracks a new value when incrementing a value that doesnt exists' do
			app_token = valid_app_token
			@profile_tracker.perform({
				'app_token' => app_token,
				'external_id' => 'lpvasco',
				'created_at' => 123456,
				'properties' => {
					'name' => 'Luiz'
				}
			})
			@profile_tracker.perform({
				'app_token' => app_token,
				'external_id' => 'lpvasco',
				'created_at' => 123456,
				'properties' => {
					'$inc.age' => 3
				}
			})
			property = @properties.find.first
			expect(property).to eq({
				'_id' => property['_id'],
				'key' => app_token + '#profiles',
				'properties' => {
					'name' => {
						'type' => 'string',
						'values' => {
							'Luiz' => 1
						}
					},
					'age' => {
						'type' => 'number',
						'values' => {
							'3' => 1
						}
					}
				}
			})
		end
	end
end