# typed: strict
# frozen_string_literal: true

module Views
  module FleetRadar
    class Index < Views::Base
      extend T::Sig

      sig do
        params(
          telemetry_items: T.nilable(T::Array[FleetRadarController::DriverTelemetryData]),
          current_merchant: T.nilable(Merchant),
          merchants: T.nilable(T::Array[Merchant])
        ).void
      end
      def initialize(telemetry_items:, current_merchant:, merchants:)
        @telemetry_items = T.let(telemetry_items || [], T::Array[FleetRadarController::DriverTelemetryData])
        @current_merchant = T.let(current_merchant, T.nilable(Merchant))
        @merchants = T.let(merchants || [], T::Array[Merchant])
      end

      sig { void }
      def view_template
        render Views::Layouts::ApplicationLayout.new(
          title: "FleetRadar Live Telemetry | Fashion Fulfillment OMS",
          current_merchant: @current_merchant,
          merchants: @merchants,
          current_path: fleet_radar_path
        ) do
          # Leaflet CSS & JS
          link(rel: "stylesheet", href: "https://unpkg.com/leaflet@1.9.4/dist/leaflet.css", integrity: "sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY=", crossorigin: "")
          script(src: "https://unpkg.com/leaflet@1.9.4/dist/leaflet.js", integrity: "sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo=", crossorigin: "")

          # Header Row
          div(class: "flex flex-wrap items-center justify-between gap-4 mb-6") do
            div(class: "flex items-center gap-3") do
              h1(class: "text-2xl font-bold text-white font-sans tracking-tight") { "🗺️ FleetPulse Live Courier Telemetry" }
              div(class: "inline-flex items-center gap-2 px-3 py-1 rounded-full text-xs font-semibold bg-emerald-500/15 border border-emerald-500/40 text-emerald-400") do
                div(class: "w-2 h-2 rounded-full bg-emerald-500 animate-ping")
                span { "REAL-TIME WEBSOCKET STREAM" }
              end
            end

            div(class: "text-xs text-slate-400") do
              "Merchant: "
              strong(class: "text-indigo-400 font-bold") { @current_merchant ? @current_merchant.name : "All" }
            end
          end

          # Map & Sidebar Container Grid
          div(class: "grid grid-cols-1 lg:grid-cols-[1fr_380px] gap-6 h-[calc(100vh-240px)] min-h-[550px]") do
            # Interactive Dark Leaflet Map
            div(id: "fleet-map", class: "w-full h-full rounded-2xl border border-indigo-500/30 shadow-2xl bg-[#090d16]")

            # Courier Sidebar Stream
            div(class: "radar-sidebar flex flex-col gap-3 overflow-y-auto max-h-full pr-1", id: "courier-sidebar") do
              if @telemetry_items.empty?
                div(class: "p-8 text-center rounded-xl bg-slate-900/60 border border-slate-800 text-slate-400 text-xs font-medium") do
                  "No active couriers currently on duty for this merchant."
                end
              else
                @telemetry_items.each do |driver|
                  render_courier_card(driver)
                end
              end
            end
          end

          # Client-side Leaflet Initialization Script
          render_leaflet_script
        end
      end

      private

      sig { params(driver: FleetRadarController::DriverTelemetryData).void }
      def render_courier_card(driver)
        div(
          class: "courier-card p-4 rounded-xl bg-slate-900/80 backdrop-blur-xl border border-indigo-500/20 hover:border-indigo-500/50 cursor-pointer transition-all duration-200 shadow-lg",
          id: "driver-card-#{driver.order_number}",
          data_order_number: driver.order_number,
          data_lat: driver.lat.to_s,
          data_lng: driver.lng.to_s
        ) do
          div(class: "flex items-start justify-between mb-1.5") do
            div(class: "text-sm font-bold text-white") { "🛵 #{driver.driver_name}" }
            render Components::UI::Badge.new(status: driver.status)
          end

          div(class: "text-xs text-slate-400 mb-1") do
            "🏍️ #{driver.vehicle} | Ref: "
            strong(class: "text-slate-200") { "##{driver.order_number}" }
          end

          div(class: "text-xs text-slate-400 mb-2") do
            "👤 Buyer: "
            strong(class: "text-slate-200") { driver.buyer_name }
            span(class: "text-slate-500 ml-1") { "(#{driver.shipping_address})" }
          end

          div(class: "grid grid-cols-2 gap-2 text-xs bg-slate-950/60 p-2 rounded-lg border border-slate-800/60 font-mono") do
            div do
              "⚡ Speed: "
              strong(class: "text-indigo-400") { "#{driver.speed_kmh} km/h" }
            end
            div do
              "⏱️ ETA: "
              strong(class: "text-amber-400") { "#{driver.eta_minutes} Mins" }
            end
          end
        end
      end

      sig { void }
      def render_leaflet_script
        default_lat = @telemetry_items.any? ? T.must(@telemetry_items.first).lat : -6.2088
        default_lng = @telemetry_items.any? ? T.must(@telemetry_items.first).lng : 106.8456

        json_data = @telemetry_items.map do |d|
          {
            order_number: d.order_number,
            driver_name: d.driver_name,
            driver_phone: d.driver_phone,
            vehicle: d.vehicle,
            status: d.status,
            lat: d.lat,
            lng: d.lng,
            speed_kmh: d.speed_kmh,
            eta_minutes: d.eta_minutes,
            buyer_name: d.buyer_name,
            shipping_address: d.shipping_address
          }
        end.to_json

        m_id = @current_merchant ? @current_merchant.id.to_s : ""

        js_content = <<~JS
          document.addEventListener("DOMContentLoaded", function() {
            var map = L.map('fleet-map').setView([#{default_lat}, #{default_lng}], 14);

            L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
              attribution: '&copy; OpenStreetMap &copy; CARTO',
              subdomains: 'abcd',
              maxZoom: 19
            }).addTo(map);

            window.fleetMap = map;
            window.driverMarkers = {};

            var telemetryData = #{json_data};

            telemetryData.forEach(function(item) {
              addOrUpdateMarker(item);
            });

            function createIcon(status) {
              var iconEmoji = status === 'delivered' ? '✅' : '🛵';
              return L.divIcon({
                className: 'custom-leaflet-marker',
                html: '<div class="w-9 h-9 rounded-full bg-indigo-600 border-2 border-white flex items-center justify-center text-lg shadow-lg animate-pulse">' + iconEmoji + '</div>',
                iconSize: [36, 36],
                iconAnchor: [18, 18]
              });
            }

            function addOrUpdateMarker(data) {
              var popupContent = '<div style="font-family: sans-serif; padding: 4px;">' +
                '<div style="font-weight: bold; font-size: 14px; color: #a7f3d0; margin-bottom: 4px;">🛵 ' + data.driver_name + '</div>' +
                '<div style="font-size: 12px; margin-bottom: 4px; color: #e2e8f0;">📦 Order: <strong>#' + data.order_number + '</strong> (' + data.status + ')</div>' +
                '<div style="font-size: 12px; margin-bottom: 4px; color: #cbd5e1;">👤 Buyer: <strong>' + data.buyer_name + '</strong></div>' +
                '<div style="font-size: 12px; margin-bottom: 6px; color: #94a3b8;">📍 Address: ' + data.shipping_address + '</div>' +
                '<div style="font-size: 11px; background: rgba(255,255,255,0.1); padding: 4px 6px; border-radius: 4px;">⚡ Speed: ' + data.speed_kmh + ' km/h | ⏱️ ETA: ' + data.eta_minutes + ' mins</div>' +
              '</div>';

              if (window.driverMarkers[data.order_number]) {
                var marker = window.driverMarkers[data.order_number];
                marker.setLatLng([data.lat, data.lng]);
                marker.getPopup().setContent(popupContent);
              } else {
                var newMarker = L.marker([data.lat, data.lng], { icon: createIcon(data.status) })
                  .addTo(map)
                  .bindPopup(popupContent);
                window.driverMarkers[data.order_number] = newMarker;
              }
            }

            document.querySelectorAll('.courier-card').forEach(function(card) {
              card.addEventListener('click', function() {
                var lat = parseFloat(this.dataset.lat);
                var lng = parseFloat(this.dataset.lng);
                var orderNum = this.dataset.orderNumber;
                if (window.fleetMap && lat && lng) {
                  window.fleetMap.flyTo([lat, lng], 16, { animate: true, duration: 1.2 });
                  if (window.driverMarkers[orderNum]) {
                    window.driverMarkers[orderNum].openPopup();
                  }
                }
              });
            });

            if (typeof App !== 'undefined' && App.cable) {
              App.cable.subscriptions.create(
                { channel: "FleetRadarChannel", merchant_id: "#{m_id}" },
                {
                  received: function(data) {
                    if (data && data.order_number) {
                      addOrUpdateMarker(data);
                    }
                  }
                }
              );
            }
          });
        JS

        script do
          raw(ActiveSupport::SafeBuffer.new(js_content))
        end
      end
    end
  end
end
