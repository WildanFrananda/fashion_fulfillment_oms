# typed: strict

class ApplicationController < ActionController::Base
  extend T::Sig

  allow_browser versions: :modern
  stale_when_importmap_changes

  before_action :authenticate_user!

  private

  sig { void }
  def authenticate_user!
    return if controller_name == "sessions" || controller_name == "health" || controller_name == "tracking_stream" || request.path.start_with?("/api")


    merchant_id_session = session[:merchant_id]
    staff_id_session = session[:staff_id]

    if merchant_id_session.blank? || staff_id_session.blank?
      flash[:alert] = "🔒 Please sign in to access the control center."
      redirect_to login_path and return
    end
  end

  sig { returns(Integer) }
  def active_merchant_id
    param_id = params[:merchant_id]
    if param_id.present?
      param_id.to_i
    elsif session[:merchant_id].present?
      session[:merchant_id].to_i
    else
      1
    end
  end
end
