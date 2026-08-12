# typed: strict

module Couriers
  class DispatchFleetPulseService < BaseService
    extend T::Sig

    class ResultData < T::Struct
      const :order_id, Integer
      const :order_number, String
      const :merchant_id, Integer
      const :dispatch_ref, String
      const :status, String
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
        order_id: Integer
      ).returns(BaseService::Result)
    end
    def call(merchant_id:, order_id:)
      order = order_repository.find_by_id(merchant_id: merchant_id, id: order_id)
      return failure("Order not found") unless order

      dispatch_ref = "FP-DISPATCH-#{merchant_id}-#{order.id}-#{Time.current.to_i}"

      success(
        ResultData.new(
          order_id: order_id,
          order_number: T.must(order.order_number),
          merchant_id: merchant_id,
          dispatch_ref: dispatch_ref,
          status: "dispatch_requested"
        )
      )
    end
  end
end
