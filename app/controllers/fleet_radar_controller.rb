# typed: strict

class FleetRadarController < ApplicationController
  extend T::Sig

  class DriverTelemetryData < T::Struct
    const :driver_name, String
    const :driver_phone, String
    const :vehicle, String
    const :order_number, String
    const :status, String
    const :lat, Float
    const :lng, Float
    const :speed_kmh, Integer
    const :eta_minutes, Integer
    const :dispatch_ref, String
  end

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

    order_repo = T.let(Container[:order_repository], OrderRepositoryInterface)
    active_orders = order_repo.due_today(merchant_id: merchant_id)

    telemetry_list = T.let([], T::Array[DriverTelemetryData])

    active_orders.each do |order|
      next unless ["dispatched", "in_transit", "delivered"].include?(order.status)

      order_id_num = order.id
      dispatch_ref = "FP-DISPATCH-#{merchant_id}-#{order_id_num}-#{order.created_at.to_i}"

      lat_offset = (order_id_num % 10) * 0.001
      lng_offset = (order_id_num % 5) * 0.001

      driver_phone_num = order.buyer_phone.presence || "0812-3456-7890"

      telemetry_list << DriverTelemetryData.new(
        driver_name: "FleetPulse Courier (Ref ##{order.order_number})",
        driver_phone: driver_phone_num,
        vehicle: "FleetPulse Express",
        order_number: T.must(order.order_number),
        status: T.must(order.status),
        lat: -6.2088 + lat_offset,
        lng: 106.8456 + lng_offset,
        speed_kmh: 30 + (order_id_num % 20),
        eta_minutes: 5 + (order_id_num % 15),
        dispatch_ref: dispatch_ref
      )
    end


    @telemetry_items = T.let(telemetry_list, T.nilable(T::Array[DriverTelemetryData]))
    render layout: "dashboard"
  end
end
