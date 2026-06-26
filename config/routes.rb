# frozen_string_literal: true

Discourse::Application.routes.draw { mount ::DiscourseTurnstile::Engine, at: "turnstile" }

DiscourseTurnstile::Engine.routes.draw { post "/create" => "turnstile#create" }
