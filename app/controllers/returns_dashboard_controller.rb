# typed: strict

class ReturnsDashboardController < ApplicationController
  extend T::Sig

  sig { void }
  def index
    merchant_id_param = params[:merchant_id]
    merchant_repo = T.let(Container[:merchant_repository], MerchantRepositoryInterface)
    merchants = Merchant.order(:name).to_a
    @merchants = T.let(merchants, T.nilable(T::Array[Merchant]))

    selected_merchant = if merchant_id_param.present?
      merchant_repo.find_by_id(merchant_id_param.to_i)
    else
      merchants.first
    end

    @current_merchant = T.let(selected_merchant || merchants.first, T.nilable(Merchant))
    current = @current_merchant
    merchant_id = current ? current.id : 1

    return_repo = T.let(Container[:return_repository], ReturnRepositoryInterface)
    returns = return_repo.find_by_merchant(merchant_id: merchant_id)


    @return_items = T.let(returns, T.nilable(T::Array[Return]))
    render layout: "dashboard"
  end

  sig { void }
  def update_status
    return_id = params[:id].to_i
    merchant_id_param = params[:merchant_id]
    merchant_id = merchant_id_param.present? ? merchant_id_param.to_i : 1
    new_status = params[:status].to_s

    service = T.let(Container[:update_return_status_service], Returns::UpdateReturnStatusService)
    result = service.call(merchant_id: merchant_id, return_id: return_id, new_status: new_status)

    if result.success?
      flash[:notice] = "🔄 Return ##{return_id} status updated to '#{new_status.tr('_', ' ').capitalize}'!"
    else
      flash[:alert] = "⚠️ Failed to update return status: #{result.error}"
    end

    redirect_to returns_dashboard_path(merchant_id: merchant_id)
  end
end
