# typed: strict

module Orders
  class GetOrderQueueService < BaseService
    extend T::Sig

    class OrderItemData < T::Struct
      const :sku, String
      const :product_name, String
      const :quantity, Integer
      const :price, BigDecimal
    end

    class OrderCardData < T::Struct
      const :id, Integer
      const :order_number, String
      const :status, String
      const :buyer_name, String
      const :shipping_address, String
      const :same_day_cutoff_at, T.any(Time, ActiveSupport::TimeWithZone)
      const :sla_urgency, String
      const :items, T::Array[OrderItemData]
    end

    sig { returns(OrderRepositoryInterface) }
    attr_reader :order_repository

    sig { params(order_repository: OrderRepositoryInterface).void }
    def initialize(
      order_repository: T.let(Container[:order_repository], OrderRepositoryInterface)
    )
      super()
      @order_repository = order_repository
    end

    sig { params(merchant_id: Integer).returns(BaseService::Result) }
    def call(merchant_id:)
      orders = order_repository.due_today(merchant_id: merchant_id)
      now = Time.current

      result_cards = orders.map do |order|
        cutoff = T.must(order.same_day_cutoff_at)
        urgency = compute_sla_urgency(cutoff: cutoff, now: now)

        items_data = order.order_items.map do |item|
          OrderItemData.new(
            sku: T.must(item.sku),
            product_name: T.must(item.product_name),
            quantity: T.must(item.quantity),
            price: BigDecimal(T.must(item.price).to_s)
          )
        end

        OrderCardData.new(
          id: order.id,
          order_number: T.must(order.order_number),
          status: T.must(order.status),
          buyer_name: T.must(order.buyer_name),
          shipping_address: T.must(order.shipping_address),
          same_day_cutoff_at: cutoff,
          sla_urgency: urgency,
          items: items_data
        )
      end

      success(result_cards)
    end

    private

    sig do
      params(
        cutoff: T.any(Time, ActiveSupport::TimeWithZone),
        now: T.any(Time, ActiveSupport::TimeWithZone)
      ).returns(String)
    end
    def compute_sla_urgency(cutoff:, now:)
      cutoff_time = cutoff.to_time
      now_time = now.to_time

      return "overdue" if now_time > cutoff_time
      return "due_soon" if (cutoff_time - now_time) <= 3600

      "due_today"
    end
  end
end
