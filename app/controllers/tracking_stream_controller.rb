# typed: strict
# frozen_string_literal: true

class TrackingStreamController < ApplicationController
  skip_before_action :require_login, raise: false
  include ActionController::Live
  extend T::Sig


  sig { void }
  def stream
    response.headers["Content-Type"] = "text/event-stream"
    response.headers["Cache-Control"] = "no-cache"
    response.headers["Connection"] = "keep-alive"
    response.headers["Last-Modified"] = Time.current.httpdate

    order_number = T.cast(params[:order_number], T.nilable(String)) || "ORD-TRACK"

    response.stream.write("event: connected\ndata: {\"order_number\":\"#{order_number}\",\"status\":\"streaming\"}\n\n")

    # Stream telemetry frames to buyer UI
    5.times do |i|
      sleep(0.5)
      payload = {
        order_number: order_number,
        latitude: -6.175392 + (i * 0.001),
        longitude: 106.827153 + (i * 0.001),
        speed_kmh: 35.5,
        status: "in_transit",
        eta_minutes: 15 - i,
        timestamp: Time.current.iso8601
      }.to_json

      response.stream.write("event: driver_location\ndata: #{payload}\n\n")
    end

    response.stream.write("event: order_completed\ndata: {\"status\":\"delivered\"}\n\n")
  rescue ActionController::Live::ClientDisconnected
    Rails.logger.info("[TrackingStreamController] Client disconnected")
  ensure
    response.stream.close
  end
end
