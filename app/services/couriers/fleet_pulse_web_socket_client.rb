# typed: strict

require "json"

module Couriers
  class FleetPulseWebSocketClient < BaseService
    extend T::Sig

    class PhoenixFrame < T::Struct
      const :topic, String
      const :event, String
      const :payload, T::Hash[String, T.untyped]
      const :ref, T.nilable(String)
      const :join_ref, T.nilable(String)
    end

    class ResultData < T::Struct
      const :merchant_id, Integer
      const :topic, String
      const :status, String
    end

    sig { returns(OrderRepositoryInterface) }
    attr_reader :order_repository

    sig { returns(Orders::UpdateOrderStatusService) }
    attr_reader :update_order_status_service

    sig do
      params(
        order_repository: OrderRepositoryInterface,
        update_order_status_service: Orders::UpdateOrderStatusService
      ).void
    end
    def initialize(
      order_repository: T.let(Container[:order_repository], OrderRepositoryInterface),
      update_order_status_service: T.let(Container[:update_order_status_service], Orders::UpdateOrderStatusService)
    )
      super()
      @order_repository = order_repository
      @update_order_status_service = update_order_status_service
    end

    sig do
      params(
        merchant_id: Integer,
        ws_url: String
      ).returns(BaseService::Result)
    end
    def connect(merchant_id:, ws_url: "ws://localhost:4000/socket/websocket")
      topic = "merchant:orders:#{merchant_id}"

      ws = Faye::WebSocket::Client.new(ws_url)

      ws.on :open do |_event|
        join_msg = build_join_frame(merchant_id: merchant_id)
        ws.send(join_msg)
      end

      ws.on :message do |event|
        frame = parse_frame(event.data.to_s)
        process_incoming_frame(merchant_id: merchant_id, frame: frame) if frame
      end

      success(
        ResultData.new(
          merchant_id: merchant_id,
          topic: topic,
          status: "connected"
        )
      )
    rescue StandardError => e
      failure("Failed to connect to FleetPulse WebSocket: #{e.message}")
    end

    sig { params(merchant_id: Integer, ref: String).returns(String) }
    def build_join_frame(merchant_id:, ref: "1")
      {
        topic: "merchant:orders:#{merchant_id}",
        event: "phx_join",
        payload: {},
        ref: ref,
        join_ref: ref
    }.to_json
    end

    sig { params(ref: String).returns(String) }
    def build_heartbeat_frame(ref: "2")
      {
        topic: "phoenix",
        event: "heartbeat",
        payload: {},
        ref: ref
      }.to_json
    end

    sig { params(json_message: String).returns(T.nilable(PhoenixFrame)) }
    def parse_frame(json_message)
      parsed = JSON.parse(json_message)
      return nil unless parsed.is_a?(Hash)

      topic = parsed["topic"].to_s
      event = parsed["event"].to_s
      payload_raw = parsed["payload"]
      payload = payload_raw.is_a?(Hash) ? payload_raw : {}
      ref = parsed["ref"]&.to_s
      join_ref = parsed["join_ref"]&.to_s

      PhoenixFrame.new(
        topic: topic,
        event: event,
        payload: payload,
        ref: ref,
        join_ref: join_ref
      )
    rescue JSON::ParserError
      nil
    end

    sig do
      params(
        merchant_id: Integer,
        frame: PhoenixFrame
      ).returns(BaseService::Result)
    end
    def process_incoming_frame(merchant_id:, frame:)
      return success(
        ResultData.new(
          merchant_id: merchant_id,
          topic: frame.topic,
          status: "acknowledged"
        )
      ) if frame.event == "phx_reply"

      if frame.event == "order_status_updated" || frame.event == "status_updated"
        order_number = frame.payload["order_number"].to_s
        new_status = frame.payload["status"].to_s

        return failure("Missing order_number or status in payload") if order_number.empty? || new_status.empty?

        order = order_repository.find_by_order_number(merchant_id: merchant_id, order_number: order_number)
        return failure("Order #{order_number} not found") unless order

        update_res = update_order_status_service.call(
          merchant_id: merchant_id,
          order_id: order.id,
          new_status: new_status
        )

        return update_res
      end

      success(ResultData.new(merchant_id: merchant_id, topic: frame.topic, status: "ignored"))
    end
  end
end
