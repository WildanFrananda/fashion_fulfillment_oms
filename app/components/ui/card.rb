# typed: strict
# frozen_string_literal: true

module Components
  module UI
    class Card < Components::Base
      extend T::Sig

      sig do
        params(
          title: T.nilable(String),
          subtitle: T.nilable(String),
          custom_class: T.nilable(String)
        ).void
      end
      def initialize(title: nil, subtitle: nil, custom_class: nil)
        @title = T.let(title, T.nilable(String))
        @subtitle = T.let(subtitle, T.nilable(String))
        @custom_class = T.let(custom_class, T.nilable(String))
      end

      sig { params(block: T.nilable(T.proc.void)).void }
      def view_template(&block)
        div(class: card_classes) do
          if @title || @subtitle
            div(class: "mb-4 border-b border-slate-800/80 pb-3") do
              h3(class: "text-base font-semibold text-white tracking-tight") { @title } if @title
              p(class: "text-xs text-slate-400 mt-0.5") { @subtitle } if @subtitle
            end
          end

          yield if block_given?
        end
      end

      private

      sig { returns(String) }
      def card_classes
        base = "bg-slate-900/90 backdrop-blur-xl border border-slate-800/80 rounded-xl p-5 shadow-2xl transition-all duration-300 hover:border-slate-700/80"
        "#{base} #{@custom_class}".strip
      end
    end
  end
end
