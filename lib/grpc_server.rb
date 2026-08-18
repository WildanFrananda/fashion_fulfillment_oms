# typed: strict
# frozen_string_literal: true

require_relative "generated/fulfillment/v1/fulfillment_service_services_pb"
require_relative "generated/fulfillment/v1/bin_stock_service_services_pb"
require_relative "../app/rpc/fulfillment_service_handler"
require_relative "../app/rpc/bin_stock_service_handler"

module OMS
  class GrpcServer
    extend T::Sig

    sig { params(port: Integer).void }
    def self.run(port: 50051)
      server = GRPC::RpcServer.new
      server.add_http2_port("0.0.0.0:#{port}", :this_port_is_insecure)
      server.handle(Rpc::FulfillmentServiceHandler.new)
      server.handle(Rpc::BinStockServiceHandler.new)

      puts "🚀 OMS gRPC Server running on 0.0.0.0:#{port}"
      server.run_till_terminated_or_interrupted([ 15, "INT", "TERM" ])
    end
  end
end
