# typed: strict
# frozen_string_literal: true

module Components
  module Layout
    class Navbar < Components::Base
      extend T::Sig

      sig do
        params(
          current_merchant: T.nilable(Merchant),
          merchants: T.nilable(T::Array[Merchant]),
          current_path: String
        ).void
      end
      def initialize(current_merchant:, merchants:, current_path:)
        @current_merchant = T.let(current_merchant, T.nilable(Merchant))
        @merchants = T.let(merchants || [], T::Array[Merchant])
        @current_path = T.let(current_path, String)
      end

      sig { void }
      def view_template
        div(class: "navbar flex items-center justify-between px-6 py-4 bg-slate-900/90 backdrop-blur-xl border-b border-slate-800/80 mb-6") do
          div(class: "brand-title flex items-center gap-3") do
            span(class: "text-lg font-bold text-white tracking-wide") { "🏬 Fashion Fulfillment OMS" }
            span(class: "brand-badge text-xs px-2.5 py-1 rounded-full font-semibold bg-indigo-500/10 text-indigo-400 border border-indigo-500/20") do
              @current_merchant ? @current_merchant.name : "Select Merchant"
            end
          end

          div(class: "flex items-center gap-6") do
            div(class: "live-status flex items-center gap-2 text-xs font-medium text-emerald-400") do
              div(class: "pulse-dot w-2 h-2 rounded-full bg-emerald-500 animate-ping")
              span { "Action Cable Stream Active" }
            end

            form(action: @current_path, method: "get", class: "inline-block") do
              select(
                name: "merchant_id",
                class: "merchant-select bg-slate-800 text-white text-xs rounded-lg px-3 py-1.5 border border-slate-700 focus:outline-none focus:ring-2 focus:ring-indigo-500",
                data_auto_submit: "true"
              ) do
                @merchants.each do |m|
                  if @current_merchant && @current_merchant.id == m.id
                    option(value: m.id.to_s, selected: true) { m.name }
                  else
                    option(value: m.id.to_s) { m.name }
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
