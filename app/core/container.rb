# typed: strict

require "dry/container"
require "dry/auto_inject"

class Container
  extend Dry::Container::Mixin
end

AutoInject = T.let(Dry::AutoInject(Container), T.untyped)
