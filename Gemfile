# A sample Gemfile
# We use http rather than https due to difficulties navigating the proxy otherwise
source "http://rubygems.org"

gem 'rails', '~>4.0.2'
gem 'puma'

gem 'sass-rails', '>= 3.2'
gem 'therubyracer'
gem 'uglifier', '>= 1.3.0'
gem 'jquery-rails'
gem 'bootstrap-sass'
gem 'bootstrap-datepicker-rails'
gem 'hashie'
gem 'exception_notification'

gem 'sequencescape-client-api',
  :git     => 'git+ssh://git@github.com/JamesGlover/sequencescape-client-api.git',
  :branch  => 'rails_4',
  :require => 'sequencescape'
gem 'sanger_barcode',
  :git     => 'git+ssh://git@github.com/sanger/sanger_barcode.git'

group :development do
  gem "pry"
end

group :test do
  gem 'mocha'
end
