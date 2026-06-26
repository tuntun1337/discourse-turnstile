# frozen_string_literal: true

module ::DiscourseTurnstile
  class TurnstileController < ::ApplicationController
    requires_plugin DiscourseTurnstile::PLUGIN_NAME

    before_action :ensure_config
    TOKEN_TTL = 2.minutes
    protect_from_forgery except: [:create]

    def create
      temp_id = SecureRandom.uuid
      store_token_in_redis(temp_id)
      set_encrypted_cookie(temp_id)

      render json: { success: "OK" }
    end

    private

    def ensure_config
      raise "not enabled" unless SiteSetting.discourse_turnstile_enabled
      raise "token is missing" if params[:token].blank?
    end

    def store_token_in_redis(temp_id)
      Discourse.redis.setex("turnstileToken_#{temp_id}", TOKEN_TTL.to_i, params[:token])
    end

    def set_encrypted_cookie(temp_id)
      cookies.encrypted[:turnstile_temp_id] = cookie_options.merge({ value: temp_id })
    end

    def cookie_options
      same_site = SiteSetting.same_site_cookies == "Disabled" ? nil : SiteSetting.same_site_cookies
      {
        httponly: true,
        secure: SiteSetting.force_https,
        expires: TOKEN_TTL.from_now,
        same_site: same_site,
      }.compact
    end
  end
end
