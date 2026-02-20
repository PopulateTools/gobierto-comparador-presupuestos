source 'https://rubygems.org'

gem "rails", "~> 7.1.4"
gem "sqlite3", "~> 1.7"
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
# Connection pool v3 is not compatible with Rails 8.1
gem "connection_pool", "<3"

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

# Ruby requirements
gem "stringio", "3.1.1"

gem 'puma', '~> 6.4', '>= 6.4.3'

group :development, :test do
  gem "byebug", platform: :mri
  gem "spring"
  gem "spring-watcher-listen", "~> 2.0.0"
  gem "rb-readline"
end

group :test do
  gem 'database_cleaner'
  gem 'rspec-rails', '~> 6.1'
  gem 'capybara'
  gem 'launchy'
  gem 'email_spec'
  gem 'selenium-webdriver'
  gem 'rack-test', require: "rack/test"
end

group :development do
  gem "rubocop"
end
