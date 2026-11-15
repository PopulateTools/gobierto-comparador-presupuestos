source 'https://rubygems.org'

gem "rails", "~> 8.1.0"
gem "sqlite3", "~> 2.9"
gem 'sass-rails', '~> 5.0.0'
gem 'uglifier', '>= 1.3.0'
gem 'redcarpet', require: true
gem 'bcrypt'
gem 'meta-tags'
gem 'ine-places'
gem 'actionpack-action_caching'
gem "actionpack-page_caching"
gem 'ruby_px'
gem "kaminari", "~> 1.2"
gem 'responders'
gem 'config'
gem 'dalli'
gem "aws-ses", git: "https://github.com/zebitex/aws-ses.git", ref: "78-sigv4-problem"
gem 'cocoon'
gem 'nokogiri', '~> 1.19'
gem 'json', '~> 2.1'
gem "gobierto_budgets_data", git: "https://github.com/PopulateTools/gobierto_budgets_data.git"
gem "bootsnap"
gem 'sprockets', '~> 3.7.2'
gem "i18n-tasks"

# Socrata integration
gem 'soda-ruby', '~> 0.2.24', require: 'soda'

# Frontend
gem 'jquery-rails'
gem 'jquery-turbolinks'
gem "bourbon"
gem 'turbolinks'
gem 'cookies_eu'
gem 'flight-for-rails'
gem "i18n-js", "~> 3.9.2"

# Elastic search
gem 'oj'
gem 'hashie'

# Log
gem "lograge"

# Redirections
gem 'rack-rewrite', '~> 1.5.0'

# Standard library gems no longer bundled with Ruby
gem "csv"

gem 'puma', '~> 8.1'

group :development, :test do
  gem "byebug", platform: :mri
  gem "rb-readline"
end

group :test do
  gem 'rspec-rails', '~> 8.0'
end

group :development do
  gem "rubocop"
end
