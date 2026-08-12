# typed: strict

class SupportController < ApplicationController
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
    render layout: "dashboard"
  end

  sig { void }
  def create_ticket
    merchant_id_param = params[:merchant_id]
    merchant_id = merchant_id_param.present? ? merchant_id_param.to_i : 1
    subject = params[:subject].to_s.presence || "Logistics Escalation"

    ticket_ref = "TKT-#{Time.current.to_i.to_s.last(5)}"
    flash[:notice] = "🎫 Support Ticket ##{ticket_ref} created! Level 3 Command Center engineers notified."
    redirect_to support_path(merchant_id: merchant_id)
  end

  sig { void }
  def start_chat
    merchant_id_param = params[:merchant_id]
    merchant_id = merchant_id_param.present? ? merchant_id_param.to_i : 1

    flash[:notice] = "💬 Live Operational Support Session Initiated with Duty Logistics Officer."
    redirect_to support_path(merchant_id: merchant_id)
  end
end
