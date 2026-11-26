# frozen_string_literal: true

require_relative '../mastodon/snowflake'
require_relative '../mastodon/database'

module ActiveRecord
  module Tasks
    module DatabaseTasks
      original_load_schema = instance_method(:load_schema)

      define_method(:load_schema) do |db_config, *args|
        # Rails 8.0 loads the schema instead of running migrations on a new
        # database: include the post-deployment migrations in its version
        # even with SKIP_POST_DEPLOYMENT_MIGRATIONS (upstream #34089)
        Mastodon::Database.add_post_migrate_path_to_rails(force: true)

        ActiveRecord::Base.establish_connection(db_config)
        Mastodon::Snowflake.define_timestamp_id

        original_load_schema.bind(self).call(db_config, *args)

        Mastodon::Snowflake.ensure_id_sequences_exist
      end
    end
  end
end
