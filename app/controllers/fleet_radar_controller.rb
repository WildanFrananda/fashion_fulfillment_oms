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
    const :buyer_name, String
    const :shipping_address, String
  end

  sig { void }
  def index
    merchant_repo = T.let(Container[:merchant_repository], MerchantRepositoryInterface)
    merchants = Merchant.order(:name).to_a
    @merchants = T.let(merchants, T.nilable(T::Array[Merchant]))

    merchant_id = active_merchant_id
    selected_merchant = merchant_repo.find_by_id(merchant_id)

    @current_merchant = T.let(selected_merchant || merchants.first, T.nilable(Merchant))

    current = T.must(@current_merchant)
    merchant_id = current.id
    base_lat = current.latitude_float
    base_lng = current.longitude_float

    order_repo = T.let(Container[:order_repository], OrderRepositoryInterface)
    active_orders = order_repo.due_today(merchant_id: merchant_id)

    telemetry_list = T.let([], T::Array[DriverTelemetryData])

    active_orders.each do |order|
      next unless [ "received", "packing", "dispatched", "in_transit", "delivered" ].include?(order.status)

      order_id_num = order.id
      dispatch_ref = "FP-DISPATCH-#{merchant_id}-#{order_id_num}-#{order.created_at.to_i}"

      elapsed_sec = [ (Time.current - order.updated_at).to_f, 0.0 ].max
      progress = order.status == "delivered" ? 1.0 : [ (elapsed_sec / 1800.0), 1.0 ].min

      target_lat_offset = (((order_id_num * 17) % 60) - 30) * 0.001
      target_lng_offset = (((order_id_num * 23) % 60) - 30) * 0.001

      target_lat = base_lat + target_lat_offset
      target_lng = base_lng + target_lng_offset

      current_lat = (base_lat + ((target_lat - base_lat) * progress)).round(6).to_f
      current_lng = (base_lng + ((target_lng - base_lng) * progress)).round(6).to_f

      calc_speed = order.status == "delivered" ? 0 : [ 20 + ((order_id_num * 7) % 30), 60 ].min
      calc_eta = order.status == "delivered" ? 0 : [ ((1.0 - progress) * 25).ceil, 1 ].max

      phone = order.buyer_phone.presence || "0812-#{1000 + order_id_num}-#{2000 + order_id_num}"
      buyer = order.buyer_name.presence || "Buyer ##{order_id_num}"
      address = order.shipping_address.presence || "Destination Area ##{order_id_num}"

      telemetry_list << DriverTelemetryData.new(
        driver_name: "FleetPulse Driver (##{order.order_number})",
        driver_phone: phone,
        vehicle: "FleetPulse Express Unit ##{(order_id_num % 12) + 1}",
        order_number: T.must(order.order_number),
        status: T.must(order.status),
        lat: current_lat,
        lng: current_lng,
        speed_kmh: calc_speed,
        eta_minutes: calc_eta,
        dispatch_ref: dispatch_ref,
        buyer_name: buyer,
        shipping_address: address
      )
    end

    render Views::FleetRadar::Index.new(
      telemetry_items: telemetry_list,
      current_merchant: @current_merchant,
      merchants: @merchants
    ), layout: false
  end
end
