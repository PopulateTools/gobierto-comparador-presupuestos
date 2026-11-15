ENV["RAILS_ENV"] ||= 'test'
ENV["GOBIERTO_DATA_TOKEN"] ||= "test-token"
require 'spec_helper'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'capybara/rspec'

Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  config.use_transactional_fixtures = true

  config.infer_spec_type_from_file_location!

  config.include(Factories)
  config.include ActiveSupport::Testing::TimeHelpers

  config.before(:suite) do
    ElasticsearchFixtures.load
  end

  config.after(:each) do
    travel_back
    ActionMailer::Base.deliveries.clear
  end
end
