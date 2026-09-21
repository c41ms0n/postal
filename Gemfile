# frozen_string_literal: true

source "https://rubygems.org"
gem "abbrev"
gem "authie"
gem "autoprefixer-rails"
gem "bcrypt"
gem "chronic"
gem "domain_name"
gem "dotenv"
gem "dynamic_form"
gem "execjs", "~> 2.7", "< 2.8"
gem "gelf"
gem "haml"
gem "hashie"
gem "highline", require: false
gem "jwt"
gem "kaminari"
gem "klogger-logger"
gem "konfig-config", "~> 3.0"
gem "logger"
gem "mail"
gem "mutex_m"
gem "mysql2"
gem "nifty-utils"
gem "nilify_blanks"
gem "nio4r"
gem "ostruct"
gem "pg"
gem "prometheus-client"
gem "puma"
gem "rackup"
gem "rails", "= 7.1.6"
gem "resolv"
gem "secure_headers"
gem "sentry-rails"
gem "turbolinks", "~> 5"
gem "webrick"

group :oidc do
  # These are gems which are needed for OpenID connect. They are only required by the application
  # when OIDC is enabled in the Postal configuration.
  gem "omniauth_openid_connect"
  gem "omniauth-rails_csrf_protection"
end

group :development, :assets do
  gem "coffee-rails", "~> 5.0"
  gem "jquery-rails"
  gem "sass-rails"
  gem "uglifier", ">= 1.3.0"
end

group :development do
  gem "annotate"
  gem "rubocop"
  gem "rubocop-rails"
end

group :test do
  gem "database_cleaner-active_record"
  gem "factory_bot_rails"
  gem "rspec"
  gem "rspec-rails"
  gem "shoulda-matchers"
  gem "timecop"
  gem "webmock"
end

# Optional analytics: an embedded OLAP engine used to mirror statistics
# extracts. It needs the DuckDB C library in the image, so it is not installed
# by default. Enable it with `bundle config set --local with analytics`.
group :analytics, optional: true do
  gem "duckdb"
end

# Optional in-memory store for the live statistics. Enable it with
# `bundle config set --local with valkey`.
group :valkey, optional: true do
  gem "redis-client"
end

# Optional Aerospike store for the live statistics. Enable it with
# `bundle config set --local with aerospike`.
group :aerospike, optional: true do
  gem "aerospike"
end

# Optional SQLite adapter for the message database. Enable it with
# `bundle config set --local with sqlite`.
group :sqlite, optional: true do
  gem "sqlite3"
end

# Optional S3-compatible blob store backend. Enable it with
# `bundle config set --local with s3`.
group :s3, optional: true do
  gem "aws-sdk-s3"
end
