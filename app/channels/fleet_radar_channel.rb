# typed: strict

class FleetRadarChannel < ApplicationCable::Channel
  extend T::Sig

  sig { void }
  def subscribed
    merchant_id = params[:merchant_id]
    if merchant_id.present?
      stream_from "fleet_radar:merchant:#{merchant_id}"
    else
      reject
    end
  end

  sig { void }
  def unsubscribed
    stop_all_streams
  end
end
