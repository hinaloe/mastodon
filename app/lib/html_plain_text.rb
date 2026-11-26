# frozen_string_literal: true

# Text content of an HTML snippet, with entities decoded.
#
# Since Rails 8.0, `strip_tags` keeps entities encoded ("Let&#39;s",
# "a=1&amp;b=2"). Use this where the result is used as plain text (URLs,
# JSON, text e-mails, attributes escaped again by Rails), as `strip_tags`
# did before.
module HtmlPlainText
  def self.call(html)
    HTMLEntities.new.decode(ActionController::Base.helpers.strip_tags(html.to_s))
  end
end
