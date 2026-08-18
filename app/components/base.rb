# typed: strict
# frozen_string_literal: true

module Components
  class Base < Phlex::HTML
    extend T::Sig

    include Phlex::Rails::Helpers::Routes

    if Rails.env.development?
      sig { void }
      def before_template
        comment { "Before #{self.class.name}" }
        super
      end
    end
  end
end
