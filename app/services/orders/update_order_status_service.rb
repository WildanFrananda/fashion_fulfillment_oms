# typed: strict

module Orders
  class UpdateOrderStatusService < BaseService
    extend T::Sig

    class ResultData < T::Struct
      const :id, Integer
      const :order_number, String
      const :status, String
      const :updated_at, T.any(Time, ActiveSupport::TimeWithZone)
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

    sig do
      params(
        merchant_id: Integer,
        order_id: Integer,
        new_status: String
      ).returns(BaseService::Result)
    end
    def call(merchant_id:, order_id:, new_status:)
      order = order_repository.find_by_id(merchant_id: merchant_id, id: order_id)
      return failure("Order not found") unless order

      updated_order = order_repository.update_status(merchant_id: merchant_id, order_id: order_id, status: new_status)
      return failure("Failed to update order status") unless updated_order

      updated_at = Time.current

      ActionCable.server.broadcast(
        "merchant:orders:#{merchant_id}",
        {
          order_id: order_id,
          order_number: updated_order.order_number,
          status: new_status,
          updated_at: updated_at.iso8601
        }
      )

      success(
        ResultData.new(
          id: updated_order.id,
          order_number: T.must(updated_order.order_number),
          status: T.must(updated_order.status),
          updated_at: updated_at
        )
      )
    end
  end
end
