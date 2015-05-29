class Ability
  include CanCan::Ability

  def initialize(user)

    can :update, App do |app|
      auth = Authorization.where(:user_id => user.id, :app_id => app.id).first
      auth != nil
    end

    can :manage, App do |app|
      auth = Authorization.where(:user_id => user.id, :app_id => app.id).first
      auth && auth.admin == true
    end
  end
end
