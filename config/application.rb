require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module FashionFulfillmentOms
  class Application < Rails::Application
    $LOAD_PATH.unshift(File.expand_path("../lib/generated", __dir__))
    config.load_defaults 8.1


    config.autoload_lib(ignore: %w[assets tasks generated])
  end
end
