# frozen_string_literal: true

# Extra directories for `bin/rails stats`. Rails 8.0 deprecated
# STATS_DIRECTORIES in favor of Rails::CodeStatistics.register_directory.
return unless defined?(Rails::Command::StatsCommand)

[
  %w(App\ Libraries app/lib),
  %w(Presenters app/presenters),
  %w(Services app/services),
  %w(Validators app/validators),
  %w(Workers app/workers),
].each do |name, directory|
  Rails::CodeStatistics.register_directory(name, directory)
end
