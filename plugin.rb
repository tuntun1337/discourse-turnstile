# coding: utf-8
# frozen_string_literal: true

# name: discourse-turnstile
# about: Cloudflare Turnstile captcha on the Discourse signup form (fork of discourse-hcaptcha)
# version: 0.1.0
# authors: tuntun1337
# url: https://github.com/tuntun1337/discourse-turnstile
# required_version: 2.7.0

enabled_site_setting :discourse_turnstile_enabled

extend_content_security_policy(script_src: %w[https://challenges.cloudflare.com])

module ::DiscourseTurnstile
  PLUGIN_NAME = "discourse-turnstile"
end

require_relative "lib/discourse_turnstile/engine"

after_initialize do
  reloadable_patch { UsersController.include(DiscourseTurnstile::CreateUsersControllerPatch) }

  require_relative "app/services/problem_check/turnstile_configuration.rb"
  register_problem_check ProblemCheck::TurnstileConfiguration
end
