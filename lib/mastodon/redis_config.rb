# frozen_string_literal: true

def setup_redis_env_url(prefix = nil, defaults = true)
  prefix = prefix.to_s.upcase + '_' unless prefix.nil?
  prefix = '' if prefix.nil?

  return if ENV[prefix + 'REDIS_URL'].present?

  password = ENV.fetch(prefix + 'REDIS_PASSWORD') { '' if defaults }
  host     = ENV.fetch(prefix + 'REDIS_HOST') { 'localhost' if defaults }
  port     = ENV.fetch(prefix + 'REDIS_PORT') { 6379 if defaults }
  db       = ENV.fetch(prefix + 'REDIS_DB') { 0 if defaults }

  ENV[prefix + 'REDIS_URL'] = begin
    if [password, host, port, db].all?(&:nil?)
      ENV['REDIS_URL']
    else
      Addressable::URI.parse("redis://#{host}:#{port}/#{db}").tap do |uri|
        uri.password = password if password.present?
      end.normalize.to_str
    end
  end
end

setup_redis_env_url
setup_redis_env_url(:cache, false)
setup_redis_env_url(:sidekiq, false)

namespace         = ENV.fetch('REDIS_NAMESPACE', nil)
cache_namespace   = namespace ? namespace + '_cache' : 'cache'
sidekiq_namespace = namespace

REDIS_CACHE_PARAMS = {
  driver: :hiredis,
  url: ENV['CACHE_REDIS_URL'],
  expires_in: 10.minutes,
  namespace: cache_namespace,
  pool_size: Sidekiq.server? ? Sidekiq.options[:concurrency] : Integer(ENV['MAX_THREADS'] || 5),
  pool_timeout: 5,
}.freeze

# Cache entries include Active Record objects dumped with Marshal, whose
# format depends on the Rails version and on the cache and marshalling format
# settings: a process running another version can fail to load them (for
# instance Rails 6.1 reading objects written by 7.0). Keep the entries of each
# combination in their own namespace, so processes of different versions never
# share them during a rolling deploy or after a rollback. The cache starts
# empty after an upgrade.
def versioned_cache_params(config)
  versions = [
    "rails#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}",
    "cache#{config.active_support.cache_format_version || ActiveSupport::Cache.format_version}",
    ("ar#{config.active_record.marshalling_format_version}" if config.active_record.marshalling_format_version),
  ].compact

  REDIS_CACHE_PARAMS.merge(namespace: [REDIS_CACHE_PARAMS[:namespace], *versions].join(':'))
end

REDIS_SIDEKIQ_PARAMS = {
  driver: :hiredis,
  url: ENV['SIDEKIQ_REDIS_URL'],
  namespace: sidekiq_namespace,
}.freeze

if Rails.env.test?
  ENV['REDIS_NAMESPACE'] = "mastodon_test#{ENV['TEST_ENV_NUMBER']}"
end
