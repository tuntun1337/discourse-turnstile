# frozen_string_literal: true

module DiscourseTurnstile
  module CreateUsersControllerPatch
    TURNSTILE_VERIFICATION_URL = "https://challenges.cloudflare.com/turnstile/v0/siteverify".freeze

    extend ActiveSupport::Concern
    included { before_action :check_turnstile, only: [:create] }

    def check_turnstile
      return unless SiteSetting.discourse_turnstile_enabled

      turnstile_token = fetch_turnstile_token
      raise Discourse::InvalidAccess.new if turnstile_token.blank?

      response = send_turnstile_verification(turnstile_token)

      validate_turnstile_response(response)
    rescue => e
      Rails.logger.warn("Error parsing Turnstile response: #{e}")
      fail_with("turnstile_verification_failed")
    end

    private

    def send_turnstile_verification(turnstile_token)
      uri = URI.parse(TURNSTILE_VERIFICATION_URL)

      http = FinalDestination::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = FinalDestination::HTTP::Post.new(uri.request_uri)
      request.set_form_data(
        { "secret" => SiteSetting.turnstile_secret_key, "response" => turnstile_token },
      )

      http.request(request)
    end

    def fetch_turnstile_token
      temp_id = cookies.encrypted[:turnstile_temp_id]
      turnstile_token = Discourse.redis.get("turnstileToken_#{temp_id}")

      if temp_id.present?
        Discourse.redis.del("turnstileToken_#{temp_id}")
        cookies.delete(:turnstile_temp_id)
      end

      turnstile_token
    end

    def validate_turnstile_response(response)
      raise Discourse::InvalidAccess.new if response.code.to_i >= 500

      response_json = JSON.parse(response.body)
      if response_json["success"].nil? || response_json["success"] == false
        raise Discourse::InvalidAccess.new
      end
    end
  end
end
