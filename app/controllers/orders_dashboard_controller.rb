# typed: strict

class OrdersDashboardController < ApplicationController
  extend T::Sig

  sig { void }
  def index
    merchants = Merchant.order(:name).to_a
    @merchants = T.let(merchants, T.nilable(T::Array[Merchant]))

    merchant_id_param = params[:merchant_id]
    merchant_repo = T.let(Container[:merchant_repository], MerchantRepositoryInterface)

    selected_merchant = if merchant_id_param.present?
      merchant_repo.find_by_id(merchant_id_param.to_i)
    else
      merchants.first
    end

    @current_merchant = T.let(selected_merchant || merchants.first, T.nilable(Merchant))
    current = @current_merchant
    merchant_id = current ? current.id : 1

    service = T.let(Container[:get_order_queue_service], Orders::GetOrderQueueService)
    result = service.call(merchant_id: merchant_id)

    @order_cards = T.let(result.success? ? result.data : [], T.anything)
    render layout: "dashboard"
  end

  sig { void }
  def print_label
    order_id = params[:id].to_i
    merchant_id_param = params[:merchant_id]
    merchant_id = merchant_id_param.present? ? merchant_id_param.to_i : 1

    service = T.let(Container[:generate_shipping_label_service], Labels::GenerateShippingLabelService)
    result = service.call(merchant_id: merchant_id, order_id: order_id)

    if result.success?
      label_data = T.cast(result.data, Labels::GenerateShippingLabelService::ResultData)
      flash[:notice] = "🎉 Resi AWB Successfully Generated! AWB Number: #{label_data.awb_number} (Reprint Count: #{label_data.reprint_count})"
    else
      flash[:alert] = "⚠️ Failed to generate label: #{result.error}"
    end

    redirect_to orders_path(merchant_id: merchant_id)
  end


  sig { void }
  def label_view

    order_id = params[:id].to_i
    merchant_id_param = params[:merchant_id]
    merchant_id = merchant_id_param.present? ? merchant_id_param.to_i : 1

    merchant_repo = T.let(Container[:merchant_repository], MerchantRepositoryInterface)
    @merchant = T.let(merchant_repo.find_by_id(merchant_id), T.nilable(Merchant))

    order_repo = T.let(Container[:order_repository], OrderRepositoryInterface)
    @order = T.let(order_repo.find_by_id(merchant_id: merchant_id, id: order_id), T.nilable(Order))

    service = T.let(Container[:generate_shipping_label_service], Labels::GenerateShippingLabelService)
    result = service.call(merchant_id: merchant_id, order_id: order_id)

    @label = T.let(result.success? ? T.cast(result.data, Labels::GenerateShippingLabelService::ResultData) : nil, T.nilable(Labels::GenerateShippingLabelService::ResultData))
    render layout: false
  end

  sig { void }
  def dispatch_fleet_pulse
    order_id = params[:id].to_i
    merchant_id_param = params[:merchant_id]
    merchant_id = merchant_id_param.present? ? merchant_id_param.to_i : 1

    service = T.let(Container[:dispatch_fleet_pulse_service], Couriers::DispatchFleetPulseService)
    result = service.call(merchant_id: merchant_id, order_id: order_id)

    if result.success?
      update_service = T.let(Container[:update_order_status_service], Orders::UpdateOrderStatusService)
      update_service.call(merchant_id: merchant_id, order_id: order_id, new_status: "dispatched")

      dispatch_data = T.cast(result.data, Couriers::DispatchFleetPulseService::ResultData)
      flash[:notice] = "🛵 Courier Dispatch Requested to FleetPulse! Dispatch Ref: #{dispatch_data.dispatch_ref}"
    else
      flash[:alert] = "⚠️ Failed to dispatch to FleetPulse: #{result.error}"
    end

    redirect_to orders_path(merchant_id: merchant_id)
  end

  sig { void }
  def update_status
    order_id = params[:id].to_i
    merchant_id_param = params[:merchant_id]
    merchant_id = merchant_id_param.present? ? merchant_id_param.to_i : 1
    new_status = params[:status].to_s

    service = T.let(Container[:update_order_status_service], Orders::UpdateOrderStatusService)
    result = service.call(merchant_id: merchant_id, order_id: order_id, new_status: new_status)

    if result.success?
      flash[:notice] = "📦 Order ##{order_id} status updated to '#{new_status.tr('_', ' ').capitalize}'!"
    else
      flash[:alert] = "⚠️ Failed to update order status: #{result.error}"
    end

    redirect_to orders_path(merchant_id: merchant_id)
  end
end


