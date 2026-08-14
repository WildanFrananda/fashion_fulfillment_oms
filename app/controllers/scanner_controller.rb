# typed: strict

class ScannerController < ApplicationController
  extend T::Sig

  class ActiveScanItemData < T::Struct
    const :id, Integer
    const :order_number, String
    const :status, String
    const :same_day_cutoff_at, T.any(Time, ActiveSupport::TimeWithZone)
    const :sku, String
    const :product_name, String
    const :bin_location, String
    const :total_items_count, Integer
  end

  sig { void }
  def index
    merchant_id = active_merchant_id

    merchant_repo = T.let(Container[:merchant_repository], MerchantRepositoryInterface)
    merchants = Merchant.order(:name).to_a
    @merchants = T.let(merchants, T.nilable(T::Array[Merchant]))

    selected_merchant = merchant_repo.find_by_id(merchant_id)
    @current_merchant = T.let(selected_merchant || merchants.first, T.nilable(Merchant))

    order_id_param = params[:order_id]
    @active_scan_target = T.let(nil, T.nilable(ActiveScanItemData))

    if order_id_param.present?
      active_order = Order.find_by(merchant_id: merchant_id, id: order_id_param.to_i)
      if active_order
        first_item = active_order.order_items.first
        if first_item
          bin = T.cast(first_item.read_attribute(:bin_location), T.nilable(String)).presence || "Rak A-01, Bin 01"
          cutoff_val = active_order.same_day_cutoff_at || Time.current
          @active_scan_target = T.let(
            ActiveScanItemData.new(
              id: active_order.id,
              order_number: T.must(active_order.order_number),
              status: T.must(active_order.status),
              same_day_cutoff_at: cutoff_val,
              sku: T.must(first_item.sku),
              product_name: T.must(first_item.product_name),
              bin_location: bin,
              total_items_count: active_order.order_items.count
            ),
            T.nilable(ActiveScanItemData)
          )
        end
      end
    end

    render layout: false
  end

  sig { void }
  def verify
    merchant_id = active_merchant_id
    order_id = params[:order_id].to_i
    scanned_code = params[:scanned_code].to_s

    service = T.let(Container[:verify_scan_barcode_service], Orders::VerifyScanBarcodeService)
    result = service.call(merchant_id: merchant_id, order_id: order_id, scanned_code: scanned_code)

    if result.success?
      res_data = T.cast(result.data, Orders::VerifyScanBarcodeService::ResultData)
      flash[:notice] = res_data.message
    else
      flash[:alert] = result.error
    end

    redirect_to scanner_path(merchant_id: merchant_id, order_id: order_id)
  end
end
