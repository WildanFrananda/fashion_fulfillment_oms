# typed: false
# frozen_string_literal: true

require "rails_helper"
require_relative "../../app/clients/fleet_pulse_client"

RSpec.describe FleetPulse::GrpcClient do
  let(:client) { FleetPulse::GrpcClient.new(host: "localhost:50052") }

  describe "#dispatch_courier" do
    it "handles connection error gracefully when FleetPulse server is offline" do
      result = client.dispatch_courier(
        order_id: 101,
        order_number: "ORD-999",
        pickup_address: "Warehouse Central",
        delivery_address: "Sudirman Tower"
      )

      expect(result[:success]).to eq(false)
      expect(result[:driver_name]).to eq("FleetPulse Pending")
      expect(result[:vehicle]).to eq("Motorcycle")
    end
  end
end
