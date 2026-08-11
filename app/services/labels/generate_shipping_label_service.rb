# typed: strict

module Labels
  class GenerateShippingLabelService < BaseService
    extend T::Sig

    class ResultData < T::Struct
      const :id, Integer
      const :order_id, Integer
      const :awb_number, String
      const :pdf_url, String
      const :reprint_count, Integer
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

      label = order.shipping_label
      if label
        label.increment!(:reprint_count)
      else
        awb = "AWB-#{merchant_id}-#{order.order_number}-#{Time.current.to_i}"
        pdf = "/labels/#{awb}.pdf"
        label = order.create_shipping_label!(
          awb_number: awb,
          pdf_url: pdf,
          reprint_count: 1
        )
      end

      success(
        ResultData.new(
          id: label.id,
          order_id: order_id,
          awb_number: T.must(label.awb_number),
          pdf_url: T.must(label.pdf_url),
          reprint_count: T.must(label.reprint_count)
        )
      )
    end
  end
end
