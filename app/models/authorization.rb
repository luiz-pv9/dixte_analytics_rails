class Authorization
  include Mongoid::Document

  field :admin, :type => Boolean
  field :tags, :type => Array

  belongs_to :user, :class_name => 'User'
  belongs_to :app, :class_name => 'App'

  validates :app, :presence => true
  validates :user, :presence => true
end
