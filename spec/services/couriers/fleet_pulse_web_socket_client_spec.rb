# typed: false

require "rails_helper"

RSpec.describe Couriers::FleetPulseWebSocketClient, type: :service do
  let!(:merchant) { create(:merchant) }
  let!(:order) { create(:order, merchant: merchant, order_number: "ORD-FP-999", status: "packed") }
  let(:client) { described_class.new }

  describe "#build_join_frame" do
    it "constructs valid Phoenix Channel phx_join JSON frame" do
      json_str = client.build_join_frame(merchant_id: merchant.id, ref: "10")
      parsed = JSON.parse(json_str)

      expect(parsed["topic"]).to eq("merchant:orders:#{merchant.id}")
      expect(parsed["event"]).to eq("phx_join")
      expect(parsed["ref"]).to eq("10")
    end
  end

  describe "#parse_frame" do
    it "parses raw JSON string into typed PhoenixFrame struct" do
      raw_json = {
        topic: "merchant:orders:#{merchant.id}",
        event: "order_status_updated",
        payload: { "order_number" => "ORD-FP-999", "status" => "delivered" }
      }.to_json

      frame = client.parse_frame(raw_json)

      expect(frame).not_to be_nil
      expect(frame.event).to eq("order_status_updated")
      expect(frame.payload["status"]).to eq("delivered")
    end
  end

  describe "#process_incoming_frame" do
    it "updates order status when receiving order_status_updated frame from FleetPulse" do
      frame = Couriers::FleetPulseWebSocketClient::PhoenixFrame.new(
        topic: "merchant:orders:#{merchant.id}",
        event: "order_status_updated",
        payload: { "order_number" => "ORD-FP-999", "status" => "delivered" },
        ref: nil,
        join_ref: nil
      )

      result = client.process_incoming_frame(merchant_id: merchant.id, frame: frame)

      expect(result.success?).to be true
      expect(order.reload.status).to eq("delivered")
    end
  end
end
