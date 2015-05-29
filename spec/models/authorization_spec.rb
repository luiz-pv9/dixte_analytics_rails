require 'rails_helper'

RSpec.describe Authorization, :type => :model do
  before :each do
    delete_all
  end

  def valid_user
    User.create(:email => 'luiz.pv9@gmail.com', :password => '1234',
                :password_confirmation => '1234')
  end

  def valid_app
    App.create :name => 'Dixte'
  end

  it 'must have a reference to an app' do
    auth = Authorization.new(:user => valid_user)
    expect(auth).not_to be_valid
  end

  it 'must have a reference to an user' do
    auth = Authorization.new(:app => valid_app)
    expect(auth).not_to be_valid
  end

  it 'has an admin flag (boolean)' do
    user = valid_user
    app = valid_app
    auth = Authorization.new(:app => valid_app, :user => valid_user)
    auth.admin = true
    expect(auth.save).to be_truthy
  end

  it 'has an array of allowed tags' do
    user = valid_user
    app = valid_app
    auth = Authorization.new(:app => valid_app, :user => valid_user)
    auth.tags = ['something', 'something_else']
    expect(auth.save).to be_truthy
  end
end
