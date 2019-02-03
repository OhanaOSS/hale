source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# https://nvd.nist.gov/vuln/detail/CVE-2018-14404
gem "nokogiri", ">= 1.8.5"

# https://nvd.nist.gov/vuln/detail/CVE-2018-16471
gem "rack", ">= 2.0.6"

# https://nvd.nist.gov/vuln/detail/CVE-2018-16468
gem "loofah", ">= 2.2.3"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2.0'
# Use pg as the database for Active Record
gem 'pg', '~> 1.0'
# Use Puma as the app server
gem 'puma', '~> 3.11'
# Use devise_token_auth for Authentication
gem 'devise_token_auth'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.7.0'
# ActiveModel::Serializer implementation
gem 'active_model_serializers', '~> 0.10.6'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

gem 'paper_trail', '~> 9.0.2'

gem "pundit"

# Use ActiveStorage variant
# gem 'mini_magick', '~> 4.8'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
gem 'rack-cors'

group :production do
end
group :development, :test do
  gem 'pry-byebug', '~> 3.6.0'
  gem 'faker'
  gem 'dotenv-rails', '~> 2.4.0'
  gem 'factory_bot_rails', '~> 4.0'
end

group :test do
  gem 'rspec-rails', '~> 3.7'
  gem 'shoulda-matchers', '~> 3.1'
  gem 'database_cleaner'
end

group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end