# typed: strict

namespace :fleet_pulse do
  desc "Subscribe all active merchants to FleetPulse Phoenix WebSocket channel"
  task subscribe: :environment do
    puts "Starting FleetPulse Real-Time WebSocket Subscription Engine..."

    merchant_repo = Container[:merchant_repository]
    client = Container[:fleet_pulse_websocket_client]

    Merchant.find_each do |merchant|
      puts "Subscribing Merchant ID #{merchant.id} (#{merchant.name}) to FleetPulse Channel..."
      client.connect(merchant_id: merchant.id)
    end

    puts "FleetPulse WebSocket Subscription Engine is active!"
  end
end
