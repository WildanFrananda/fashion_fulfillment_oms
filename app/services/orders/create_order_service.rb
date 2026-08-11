# typed: strict

module Orders
  class CreateOrderService < BaseService
    extend T::Sig

    class ResultData < T::Struct
      const :id, Integer
      const :order_number, String
      const :status, String
      const :same_day_cutoff_at, T.any(Time, ActiveSupport::TimeWithZone)
      const :total_amount, BigDecimal
    end

    sig { returns(MerchantRepositoryInterface) }
    attr_reader :merchant_repository

    sig { returns(OrderRepositoryInterface) }
    attr_reader :order_repository

    sig do
      params(
        merchant_repository: MerchantRepositoryInterface,
        order_repository: OrderRepositoryInterface
      ).void
    end
    def initialize(
      merchant_repository: T.let(Container[:merchant_repository], MerchantRepositoryInterface),
      order_repository: T.let(Container[:order_repository], OrderRepositoryInterface)
    )
      super()
      @merchant_repository = merchant_repository
      @order_repository = order_repository
    end

    sig do
      params(
        merchant_id: Integer,
        form: CreateOrderForm
      ).returns(BaseService::Result)
    end
    def call(merchant_id:, form:)
      return failure(form.errors.join(", ")) unless form.valid?

      merchant = merchant_repository.find_by_id(merchant_id)
      return failure("Merchant not found") unless merchant

      existing_order = order_repository.find_by_order_number(merchant_id: merchant_id, order_number: form.order_number)
      return failure("Order number already exists") if existing_order

      cutoff_hour = merchant.cutoff_hour || 12
      cutoff_at = calculate_cutoff_at(cutoff_hour)
      initial_status = Time.current <= cutoff_at ? "received" : "next_day"

      order = order_repository.create(
        merchant_id: merchant_id,
        attributes: {
          order_number: form.order_number,
          buyer_name: form.buyer_name,
          buyer_phone: form.buyer_phone,
          shipping_address: form.shipping_address,
          total_amount: form.total_amount,
          status: initial_status,
          same_day_cutoff_at: cutoff_at
        }
      )

      form.items.each do |item|
        order.order_items.create!(
          sku: item.sku,
          product_name: item.product_name,
          quantity: item.quantity,
          price: item.price
        )
      end

      success(
        ResultData.new(
          id: order.id,
          order_number: T.must(order.order_number),
          status: T.must(order.status),
          same_day_cutoff_at: T.must(order.same_day_cutoff_at),
          total_amount: BigDecimal(order.total_amount.to_s)
        )
      )
    end

    private

    sig { params(cutoff_hour: Integer).returns(Time) }
    def calculate_cutoff_at(cutoff_hour)
      now = Time.current
      Time.zone.local(now.year, now.month, now.day, cutoff_hour, 0, 0)
    end
  end
end
