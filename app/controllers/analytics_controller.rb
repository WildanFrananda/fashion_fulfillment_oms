# typed: strict

class AnalyticsController < ApplicationController
  extend T::Sig

  class TopProductData < T::Struct
    const :sku, String
    const :product_name, String
    const :total_units_sold, Integer
    const :total_revenue, BigDecimal
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

    order_repo = T.let(Container[:order_repository], OrderRepositoryInterface)
    all_merchant_orders = order_repo.due_today(merchant_id: merchant_id)

    total_orders_count = all_merchant_orders.size
    overdue_count = 0
    on_time_count = 0
    total_rev = BigDecimal("0")

    now = Time.current

    all_merchant_orders.each do |ord|
      amt = ord.total_amount
      total_rev += amt if amt

      cutoff = ord.same_day_cutoff_at
      if cutoff && cutoff < now && [ "received", "packing" ].include?(ord.status)
        overdue_count += 1
      else
        on_time_count += 1
      end
    end

    sla_rate_pct = total_orders_count.positive? ? ((on_time_count.to_f / total_orders_count) * 100).round(1).to_f : 100.0

    @total_orders = T.let(total_orders_count, T.nilable(Integer))
    @sla_compliance_rate = T.let(sla_rate_pct, T.nilable(Float))
    @overdue_orders_count = T.let(overdue_count, T.nilable(Integer))
    @total_revenue = T.let(total_rev, T.nilable(BigDecimal))

    # Calculate Top Selling Products dynamically from DB OrderItems
    items = OrderItem.joins(:order).where(orders: { merchant_id: merchant_id }).to_a
    top_map = T.let({}, T::Hash[String, TopProductData])

    items.each do |item|
      sku = item.sku.to_s
      next if sku.empty?

      product_name = item.product_name.to_s
      qty_val = item.quantity
      qty = qty_val ? qty_val : 1
      price_val = item.price
      item_price = price_val ? price_val : BigDecimal("0")
      item_total = item_price * qty

      if top_map.key?(sku)
        existing = T.must(top_map[sku])
        top_map[sku] = TopProductData.new(
          sku: sku,
          product_name: product_name,
          total_units_sold: existing.total_units_sold + qty,
          total_revenue: existing.total_revenue + item_total
        )
      else
        top_map[sku] = TopProductData.new(
          sku: sku,
          product_name: product_name,
          total_units_sold: qty,
          total_revenue: item_total
        )
      end
    end

    sorted_products = top_map.values.sort_by { |p| -p.total_units_sold }
    render Views::Analytics::Index.new(
      sla_compliance_rate: sla_rate_pct,
      total_orders: total_orders_count,
      overdue_orders_count: overdue_count,
      total_revenue: total_rev,
      top_products: sorted_products,
      current_merchant: @current_merchant,
      merchants: @merchants
    ), layout: false
  end
end
