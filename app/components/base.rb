# typed: strict
# frozen_string_literal: true

module Components
  class Base < Phlex::HTML
    extend T::Sig

    include Phlex::Rails::Helpers::Routes

    sig { params(args: T.untyped).returns(Phlex::SGML::SafeObject) }
    def stylesheet_link_tag(*args)
      T.unsafe(view_context).stylesheet_link_tag(*args)
    end

    sig { returns(Phlex::SGML::SafeObject) }
    def javascript_importmap_tags
      T.unsafe(view_context).javascript_importmap_tags
    end

    sig { returns(String) }
    def form_authenticity_token
      T.unsafe(view_context).form_authenticity_token
    end

    if Rails.env.development?
      sig { void }
      def before_template
        comment { "Before #{self.class.name}" }
        super
      end
    end
  end
end
