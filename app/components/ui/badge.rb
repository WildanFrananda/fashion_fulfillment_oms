# typed: strict
# frozen_string_literal: true

module Components
  module UI
    class Badge < Components::Base
      extend T::Sig

      sig { params(status: String, custom_class: T.nilable(String)).void }
      def initialize(status:, custom_class: nil)
        @status = T.let(status, String)
        @custom_class = T.let(custom_class, T.nilable(String))
      end

      sig { void }
      def view_template
        span(class: badge_classes) do
          @status.tr("_", " ").upcase
        end
      end

      private

      sig { returns(String) }
      def badge_classes
        base = "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold uppercase tracking-wider"
        color = case @status
        when "received" then "bg-blue-500/10 text-blue-400 border border-blue-500/20"
        when "packing" then "bg-amber-500/10 text-amber-400 border border-amber-500/20"
        when "dispatched" then "bg-purple-500/10 text-purple-400 border border-purple-500/20"
        when "in_transit" then "bg-cyan-500/10 text-cyan-400 border border-cyan-500/20"
        when "delivered" then "bg-emerald-500/10 text-emerald-400 border border-emerald-500/20"
        else "bg-slate-500/10 text-slate-400 border border-slate-500/20"
        end

        "#{base} #{color} #{@custom_class}".strip
      end
    end
  end
end
