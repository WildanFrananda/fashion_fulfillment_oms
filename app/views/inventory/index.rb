# typed: strict
# frozen_string_literal: true

module Views
  module Inventory
    class Index < Views::Base
      extend T::Sig

      sig do
        params(
          inventory_list: T.nilable(T::Array[InventoryController::InventoryItemData]),

          current_merchant: T.nilable(Merchant),
          merchants: T.nilable(T::Array[Merchant])
        ).void
      end
      def initialize(inventory_list:, current_merchant:, merchants:)
        @inventory_list = T.let(inventory_list || [], T::Array[InventoryController::InventoryItemData])
        @current_merchant = T.let(current_merchant, T.nilable(Merchant))
        @merchants = T.let(merchants || [], T::Array[Merchant])
      end

      sig { void }
      def view_template
        render Views::Layouts::ApplicationLayout.new(
          title: "Warehouse Inventory & Bin Locations | Fashion Fulfillment OMS",
          current_merchant: @current_merchant,
          merchants: @merchants,
          current_path: inventory_dashboard_path
        ) do
          h2(class: "text-2xl font-bold text-white mb-6 font-sans tracking-tight") { "🏭 Warehouse Inventory & Bin Location Mapping" }

          if @inventory_list.empty?
            div(class: "p-12 text-center rounded-2xl bg-slate-900/60 border border-slate-800 text-slate-400 text-sm font-medium") do
              "No inventory products mapped for this merchant."
            end
          else
            div(class: "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6") do
              @inventory_list.each do |inv|
                render_inventory_card(inv)
              end
            end
          end
        end
      end

      private

      sig { params(inv: InventoryController::InventoryItemData).void }
      def render_inventory_card(inv)
        render Components::UI::Card.new(custom_class: "border-emerald-500/30 flex flex-col justify-between h-full") do
          div do
            div(class: "flex items-center justify-between mb-4 pb-3 border-b border-slate-800") do
              span(class: "text-base font-bold text-white font-mono") { "🏷️ #{inv.sku}" }
              if inv.low_stock_warning
                span(class: "px-2.5 py-1 text-xs font-bold rounded-full bg-rose-500/15 border border-rose-500/30 text-rose-400") { "🔴 Low Stock Alert" }
              else
                render Components::UI::Badge.new(status: "delivered")
              end
            end

            div(class: "text-sm font-bold text-white mb-2 font-sans") { inv.product_name }

            div(class: "mb-4") do
              span(class: "inline-flex items-center gap-1.5 px-3 py-1 rounded-lg bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-xs font-mono font-semibold") do
                "📍 Location: #{inv.bin_location}"
              end
            end

            div(class: "p-3 rounded-lg bg-slate-950/70 border border-slate-800/80 space-y-2 text-xs font-sans") do
              div(class: "flex items-center justify-between") do
                span(class: "text-slate-400 font-medium") { "🏭 Physical Warehouse Stock" }
                span(class: "font-bold text-white font-mono") { "#{inv.physical_stock} pcs" }
              end
              div(class: "flex items-center justify-between") do
                span(class: "text-slate-400 font-medium") { "🔒 Allocated (Active Orders)" }
                span(class: "font-bold text-amber-400 font-mono") { "#{inv.allocated_stock} pcs" }
              end
              div(class: "flex items-center justify-between pt-2 border-t border-slate-800/60") do
                span(class: "text-emerald-400 font-semibold") { "✅ Available to Sell" }
                span(class: "font-bold text-emerald-400 text-sm font-mono") { "#{inv.available_stock} pcs" }
              end
            end
          end
        end
      end
    end
  end
end
