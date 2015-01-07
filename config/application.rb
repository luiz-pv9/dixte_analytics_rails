require File.expand_path('../boot', __FILE__)

# Pick the frameworks you want:
require "active_model/railtie"
# require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "sprockets/railtie"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Analytics
	class Application < Rails::Application
		# Add Resque workers to the load path
		config.autoload_paths += %W(#{config.root}/app/workers)
		config.autoload_paths += %W(#{config.root}/app/finders)
	end
end
