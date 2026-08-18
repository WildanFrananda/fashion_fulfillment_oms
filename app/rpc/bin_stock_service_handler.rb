# typed: strict
# frozen_string_literal: true

require_relative "../../lib/generated/fulfillment/v1/bin_stock_service_services_pb"

module Rpc
  class BinStockServiceHandler < Fulfillment::V1::BinStockService::Service
    extend T::Sig

    sig { void }
    def initialize
      super
    end

    sig do
      params(
        req: Fulfillment::V1::CheckBinStockRequest,
        _call: T.nilable(GRPC::ActiveCall)
      ).returns(Fulfillment::V1::CheckBinStockResponse)
    end
    def check_bin_stock(req, _call)
      merchant_repo = T.let(Container[:merchant_repository], MerchantRepositoryInterface)
      merchant = merchant_repo.find_by_api_key(req.merchant_api_key)

      unless merchant
        return Fulfillment::V1::CheckBinStockResponse.new
      end

      items = OrderItem.joins(:order).where(orders: { merchant_id: merchant.id }, sku: req.sku).to_a

      if items.empty?
        return Fulfillment::V1::CheckBinStockResponse.new(
          sku: req.sku,
          product_name: "Unknown SKU",
          physical_stock: 0,
          allocated_stock: 0,
          available_stock: 0,
          bin_location: "Rak A-01, Bin 01",
          low_stock_warning: true
        )
      end

      first_item = T.must(items.first)
      product_name = first_item.product_name || "Unknown SKU"
      raw_bin = T.cast(first_item.read_attribute(:bin_location), T.nilable(String))
      bin_loc = raw_bin.presence || "Rak A-01, Bin 01"

      total_allocated = items.sum { |it| [ "received", "packing" ].include?(T.must(it.order).status) ? (it.quantity || 0) : 0 }
      initial_physical = 50
      available = initial_physical - total_allocated

      Fulfillment::V1::CheckBinStockResponse.new(
        sku: req.sku,
        product_name: product_name,
        physical_stock: initial_physical,
        allocated_stock: total_allocated,
        available_stock: available,
        bin_location: bin_loc,
        low_stock_warning: available < 5
      )
    end

    sig do
      params(
        req: Fulfillment::V1::ReserveStockRequest,
        _call: T.nilable(GRPC::ActiveCall)
      ).returns(Fulfillment::V1::ReserveStockResponse)
    end
    def reserve_stock(req, _call)
      merchant_repo = T.let(Container[:merchant_repository], MerchantRepositoryInterface)
      merchant = merchant_repo.find_by_api_key(req.merchant_api_key)

      unless merchant
        return Fulfillment::V1::ReserveStockResponse.new(
          success: false,
          error: Common::V1::ErrorDetail.new(
            error_code: "UNAUTHORIZED",
            message: "Invalid merchant_api_key"
          )
        )
      end

      check_req = Fulfillment::V1::CheckBinStockRequest.new(
        merchant_api_key: req.merchant_api_key,
        sku: req.sku
      )
      stock_info = check_bin_stock(check_req, _call)

      if stock_info.available_stock >= req.quantity
        Fulfillment::V1::ReserveStockResponse.new(
          success: true,
          bin_location: stock_info.bin_location,
          remaining_available: stock_info.available_stock - req.quantity
        )
      else
        Fulfillment::V1::ReserveStockResponse.new(
          success: false,
          remaining_available: stock_info.available_stock,
          error: Common::V1::ErrorDetail.new(
            error_code: "INSUFFICIENT_STOCK",
            message: "Only #{stock_info.available_stock} pcs available for SKU #{req.sku}"
          )
        )
      end
    end
  end
end
