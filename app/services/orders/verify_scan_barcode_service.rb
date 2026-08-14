# typed: strict

module Orders
  class VerifyScanBarcodeService < BaseService
    extend T::Sig

    class ResultData < T::Struct
      const :order_id, Integer
      const :order_number, String
      const :matched_sku, String
      const :product_name, String
      const :new_status, String
      const :message, String
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

    sig { params(merchant_id: Integer, order_id: Integer, scanned_code: String).returns(BaseService::Result) }
    def call(merchant_id:, order_id:, scanned_code:)
      clean_code = scanned_code.strip

      if clean_code.blank?
        return failure("Scanned barcode code cannot be blank")
      end

      order = order_repository.find_by_id(merchant_id: merchant_id, id: order_id)
      return failure("Order ##{order_id} not found for this merchant") unless order

      # Match against order items SKU
      matched_item = order.order_items.find { |i| i.sku.to_s.casecmp?(clean_code) }

      # Also match against order_number or AWB tracking number
      awb_match = order.shipping_label&.awb_number&.casecmp?(clean_code)
      order_number_match = order.order_number.to_s.casecmp?(clean_code)

      if matched_item || awb_match || order_number_match
        new_status = order.status == "received" ? "packing" : "packed"
        order_repository.update_status(merchant_id: merchant_id, order_id: order.id, status: new_status)

        matched_sku_str = matched_item ? T.must(matched_item.sku) : "ORD-VERIFIED"
        product_name_str = matched_item ? T.must(matched_item.product_name) : T.must(order.order_number)

        # Real-time Action Cable Broadcast to merchant order queue stream
        ActionCable.server.broadcast(
          "merchant:orders:#{merchant_id}",
          {
            event: "order_status_updated",
            order_id: order.id,
            order_number: order.order_number,
            status: new_status,
            scanned_sku: matched_sku_str,
            updated_at: Time.current.iso8601
          }
        )

        success(
          ResultData.new(
            order_id: order.id,
            order_number: T.must(order.order_number),
            matched_sku: matched_sku_str,
            product_name: product_name_str,
            new_status: new_status,
            message: "✓ SKU MATCHED! #{product_name_str} (#{matched_sku_str}) verified."
          )
        )
      else
        expected_skus = order.order_items.map(&:sku).join(", ")
        failure("✖ SKU MISMATCH! Scanned '#{clean_code}' does not match expected SKU (#{expected_skus})")
      end
    end
  end
end
