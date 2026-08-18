# typed: strict
# frozen_string_literal: true

module Components
  module UI
    class Button < Components::Base
      extend T::Sig

      sig do
        params(
          variant: String,
          custom_class: T.nilable(String),
          type: String,
          data_toggle: T.nilable(String)
        ).void
      end
      def initialize(variant: "primary", custom_class: nil, type: "button", data_toggle: nil)
        @variant = T.let(variant, String)
        @custom_class = T.let(custom_class, T.nilable(String))
        @type = T.let(type, String)
        @data_toggle = T.let(data_toggle, T.nilable(String))
      end

      sig { params(block: T.nilable(T.proc.void)).void }
      def view_template(&block)
        attrs = T.let({ class: button_classes, type: @type }, T::Hash[Symbol, T.nilable(String)])
        attrs[:data_toggle] = @data_toggle if @data_toggle

        button(**attrs) do
          yield if block_given?
        end
      end

      private

      sig { returns(String) }
      def button_classes
        base = "inline-flex items-center justify-center px-4 py-2 text-sm font-medium rounded-lg transition-all duration-200 focus:outline-none focus:ring-2 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed"
        variant_style = case @variant
        when "primary" then "bg-indigo-600 hover:bg-indigo-500 text-white shadow-lg shadow-indigo-500/25 focus:ring-indigo-500"
        when "secondary" then "bg-slate-800 hover:bg-slate-700 text-slate-200 border border-slate-700 focus:ring-slate-500"
        when "danger" then "bg-rose-600 hover:bg-rose-500 text-white shadow-lg shadow-rose-500/25 focus:ring-rose-500"
        when "ghost" then "bg-transparent hover:bg-slate-800/50 text-slate-300 focus:ring-slate-500"
        else "bg-indigo-600 hover:bg-indigo-500 text-white focus:ring-indigo-500"
        end

        "#{base} #{variant_style} #{@custom_class}".strip
      end
    end
  end
end
