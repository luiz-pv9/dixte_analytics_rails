require 'rails_helper'

RSpec.describe 'Ability' do
  before :each do
    delete_all
    @app = App.create :name => 'Dixte'
    @user = User.create(:email => 'luiz.pv9@gmail.com',
                        :password => '1234',
                        :password_confirmation => '1234')
  end

  describe 'managing the app' do
    it 'returns true if the user is an admin of the app' do
      Authorization.create(:user => @user, :app => @app, :admin => true)
      ability = Ability.new(@user)
      expect(ability.can?(:manage, @app)).to be(true)
    end

    it 'returns false if the user is not an admin of the app' do
      Authorization.create(:user => @user, :app => @app, :admin => false)
      ability = Ability.new(@user)
      expect(ability.can?(:manage, @app)).to be(false)
    end
  end

  describe 'updating the app' do
    it 'returns true if the user is authroized in the app' do
      auth = Authorization.create(:user => @user, :app => @app, :admin => false)
      ability = Ability.new(@user)
      expect(ability.can?(:update, @app)).to be(true)
    end

    it 'returns false if not authorized in the app' do
      # auth = Authorization.create(:user => @user, :app => @app, :admin => false)
      ability = Ability.new(@user)
      expect(ability.can?(:update, @app)).to be(false)
    end
  end

  describe 'seeing events' do
  end
end
