# typed: strict

class InventoryController < ApplicationController
  extend T::Sig

  class InventoryItemData < T::Struct
    const :sku, String
    const :product_name, String
    const :bin_location, String
    const :physical_stock, Integer
    const :allocated_stock, Integer
    const :available_stock, Integer
    const :low_stock_warning, T::Boolean
  end

  sig { void }
  def index
    merchant_id_param = params[:merchant_id]
    merchant_repo = T.let(Container[:merchant_repository], MerchantRepositoryInterface)
    merchants = Merchant.order(:name).to_a
    @merchants = T.let(merchants, T.nilable(T::Array[Merchant]))

    merchant_id = active_merchant_id
    selected_merchant = merchant_repo.find_by_id(merchant_id)

    @current_merchant = T.let(selected_merchant || merchants.first, T.nilable(Merchant))

    current = @current_merchant
    merchant_id = current ? current.id : 1

    # Dynamically derive inventory bin locations and stock from order items
    order_items = OrderItem.joins(:order).where(orders: { merchant_id: merchant_id }).to_a

    items_map = T.let({}, T::Hash[String, InventoryItemData])

    order_items.each_with_index do |item, idx|
      sku = item.sku.to_s
      next if sku.empty?

      product_name = item.product_name.to_s
      item_qty = item.quantity
      qty = item_qty ? item_qty : 1

      if items_map.key?(sku)
        existing = T.must(items_map[sku])
        allocated = existing.allocated_stock + qty
        available = existing.physical_stock - allocated

        items_map[sku] = InventoryItemData.new(
          sku: sku,
          product_name: product_name,
          bin_location: existing.bin_location,
          physical_stock: existing.physical_stock,
          allocated_stock: allocated,
          available_stock: available,
          low_stock_warning: available < 5
        )
      else
        raw_bin = T.cast(item.read_attribute(:bin_location), T.nilable(String))
        bin_loc = raw_bin.presence || "Rak A-01, Bin 01"

        initial_physical = 100

        allocated = qty
        available = initial_physical - allocated

        items_map[sku] = InventoryItemData.new(
          sku: sku,
          product_name: product_name,
          bin_location: bin_loc,
          physical_stock: initial_physical,
          allocated_stock: allocated,
          available_stock: available,
          low_stock_warning: available < 5
        )
      end
    end

    @inventory_list = T.let(items_map.values, T.nilable(T::Array[InventoryItemData]))
    render layout: "dashboard"
  end
end
