# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :current_account, :record

  def initialize(current_account, record)
    @current_account = current_account
    @record          = record
  end

  # Disabled users must not keep their staff permissions, as the API does
  # not otherwise check whether the user is disabled
  def admin?
    current_user&.admin? && !current_user.disabled?
  end

  def moderator?
    current_user&.moderator? && !current_user.disabled?
  end

  def staff?
    current_user&.staff? && !current_user.disabled?
  end

  private

  def current_user
    current_account&.user
  end

  def user_signed_in?
    !current_user.nil?
  end
end
