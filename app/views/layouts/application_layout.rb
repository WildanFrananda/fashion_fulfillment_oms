# typed: strict
# frozen_string_literal: true

module Views
  module Layouts
    class ApplicationLayout < Views::Base
      extend T::Sig

      sig do
        params(
          title: String,
          current_merchant: T.nilable(Merchant),
          merchants: T.nilable(T::Array[Merchant]),
          current_path: String
        ).void
      end
      def initialize(title: "Fashion Fulfillment OMS", current_merchant: nil, merchants: nil, current_path: "/")
        @title = T.let(title, String)
        @current_merchant = T.let(current_merchant, T.nilable(Merchant))
        @merchants = T.let(merchants, T.nilable(T::Array[Merchant]))
        @current_path = T.let(current_path, String)
      end

      sig { params(block: T.proc.void).void }
      def view_template(&block)
        doctype

        html(lang: "en", class: "h-full bg-[#0b1326] text-slate-100 font-sans antialiased") do
          head do
            title { @title }
            meta(name: "viewport", content: "width=device-width,initial-scale=1")
            meta(name: "apple-mobile-web-app-capable", content: "yes")
            meta(name: "application-name", content: "Fashion Fulfillment OMS")

            link(rel: "icon", href: "/icon.png", type: "image/png")
            link(rel: "icon", href: "/icon.svg", type: "image/svg+xml")
            link(rel: "apple-touch-icon", href: "/icon.png")

            stylesheet_link_tag("application", "dashboard", "data-turbo-track": "reload")
            javascript_importmap_tags
          end

          body(class: "h-full bg-[#0b1326] text-slate-100 min-h-screen flex flex-col") do
            render Components::Layout::Navbar.new(
              current_merchant: @current_merchant,
              merchants: @merchants,
              current_path: @current_path
            )

            render Components::Layout::NavigationTabs.new(
              current_merchant: @current_merchant,
              current_path: @current_path
            )

            main(class: "flex-1 px-6 pb-12") do
              yield
            end
          end
        end
      end
    end
  end
end
