# frozen_string_literal: true

module RoutingHelper
  extend ActiveSupport::Concern

  include ActionView::Helpers::AssetTagHelper
  include ViteRails::TagHelpers

  included do
    # Since Rails 7.1, the route helpers are only defined when this is
    # included in the class itself (upstream #27189)
    include Rails.application.routes.url_helpers

    def default_url_options
      ActionMailer::Base.default_url_options
    end
  end

  def full_asset_url(source, **options)
    source = ActionController::Base.helpers.asset_url(source, **options) unless use_storage?

    URI.join(root_url, source).to_s
  end

  # Path of a file built by Vite, by its source path relative to
  # app/javascript (e.g. "images/preview.jpg").
  def frontend_asset_path(source, **options)
    path_to_asset(vite_manifest.path_for(source), **options)
  end

  def frontend_asset_url(source, **options)
    full_asset_url(frontend_asset_path(source, **options))
  end

  def use_storage?
    Rails.configuration.x.use_s3 || Rails.configuration.x.use_swift
  end
end
