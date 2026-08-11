# typed: strict

module Returns
  class InitiateReturnService < BaseService
    extend T::Sig

    class ResultData < T::Struct
      const :id, Integer
      const :merchant_id, Integer
      const :order_id, Integer
      const :reason, String
      const :status, String
    end

    sig { returns(OrderRepositoryInterface) }
    attr_reader :order_repository

    sig { returns(ReturnRepositoryInterface) }
    attr_reader :return_repository

    sig do
      params(
        order_repository: OrderRepositoryInterface,
        return_repository: ReturnRepositoryInterface
      ).void
    end
    def initialize(
      order_repository: T.let(Container[:order_repository], OrderRepositoryInterface),
      return_repository: T.let(Container[:return_repository], ReturnRepositoryInterface)
    )
      super()
      @order_repository = order_repository
      @return_repository = return_repository
    end

    sig do
      params(
        merchant_id: Integer,
        form: InitiateReturnForm
      ).returns(BaseService::Result)
    end
    def call(merchant_id:, form:)
      return failure(form.errors.join(", ")) unless form.valid?

      order = order_repository.find_by_id(merchant_id: merchant_id, id: form.order_id)
      return failure("Order not found") unless order

      existing_return = return_repository.find_by_order_id(merchant_id: merchant_id, order_id: form.order_id)
      return failure("Return request already exists for this order") if existing_return

      return_record = return_repository.create(
        merchant_id: merchant_id,
        attributes: {
          order_id: form.order_id,
          reason: form.reason,
          status: "requested"
        }
      )

      success(
        ResultData.new(
          id: return_record.id,
          merchant_id: merchant_id,
          order_id: form.order_id,
          reason: T.must(return_record.reason),
          status: T.must(return_record.status)
        )
      )
    end
  end
end
