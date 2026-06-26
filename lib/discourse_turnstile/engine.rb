# frozen_string_literal: true

module ::DiscourseTurnstile
  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace DiscourseTurnstile
    config.autoload_paths << File.join(config.root, "lib")
  end
end
