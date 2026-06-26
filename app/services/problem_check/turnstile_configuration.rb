# frozen_string_literal: true

class ProblemCheck::TurnstileConfiguration < ProblemCheck
  self.priority = "high"

  def call
    return problem if SiteSetting.discourse_turnstile_enabled && !turnstile_credentials_present?

    no_problem
  end

  private

  def turnstile_credentials_present?
    SiteSetting.turnstile_site_key.present? && SiteSetting.turnstile_secret_key.present?
  end
end
