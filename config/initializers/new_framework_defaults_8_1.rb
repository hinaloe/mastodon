# frozen_string_literal: true

# Rails 8.1 framework defaults that this app overrides.

# Some redirects use URLs provided by remote servers (remote follow and
# interaction templates, the URL of remote statuses). Rails 8.1 raises when
# such a URL has no scheme or host; keep redirecting (relative to this host)
# and log it, as before, instead of returning a 500 error.
Rails.application.config.action_controller.action_on_path_relative_redirect = :log
