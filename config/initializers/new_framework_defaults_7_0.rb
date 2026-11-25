# frozen_string_literal: true

# Rails 7.0 framework defaults that this app overrides.

# Several actions redirect to other hosts on purpose (media and backups on
# object storage, remote statuses, the streaming API, and the confirmation
# redirect of OAuth applications inside Devise, where `allow_other_host`
# cannot be passed). Keep allowing them, as upstream does.
# (`raise_on_open_redirects = false` before Rails 8.1)
Rails.application.config.action_controller.action_on_open_redirect = :log

# Rails 7.0 lowers the SMTP open and read timeouts to 5 seconds when they are
# not set. Keep Net::SMTP's defaults (30 and 60 seconds), which the production
# configuration relied on.
Rails.application.config.action_mailer.smtp_timeout = nil
