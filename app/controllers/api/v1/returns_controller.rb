# typed: strict

module Api
  module V1
    class ReturnsController < ApplicationController
      extend T::Sig

      sig { void }
      def create
        header = request.headers["X-Merchant-Api-Key"].to_s.strip
        api_key = header.empty? ? params[:api_key].to_s : header
        return render json: { error: "Unauthorized: Missing API Key" }, status: :unauthorized if api_key.empty?

        merchant_repo = T.let(Container[:merchant_repository], MerchantRepositoryInterface)
        merchant = merchant_repo.find_by_api_key(api_key)
        return render json: { error: "Unauthorized: Invalid API Key" }, status: :unauthorized unless merchant

        form = Returns::InitiateReturnForm.new(
          order_id: params[:order_id].to_i,
          reason: params[:reason].to_s
        )

        service = T.let(Container[:initiate_return_service], Returns::InitiateReturnService)
        result = service.call(merchant_id: merchant.id, form: form)

        if result.success?
          render json: result.data, status: :created
        else
          render json: { error: result.error }, status: :unprocessable_entity
        end
      end

      sig { void }
      def update_status
        header = request.headers["X-Merchant-Api-Key"].to_s.strip
        api_key = header.empty? ? params[:api_key].to_s : header
        return render json: { error: "Unauthorized: Missing API Key" }, status: :unauthorized if api_key.empty?

        merchant_repo = T.let(Container[:merchant_repository], MerchantRepositoryInterface)
        merchant = merchant_repo.find_by_api_key(api_key)

        return render json: { error: "Unauthorized: Invalid API Key" }, status: :unauthorized unless merchant

        service = T.let(Container[:update_return_status_service], Returns::UpdateReturnStatusService)
        result = service.call(
          merchant_id: merchant.id,
          return_id: params[:id].to_i,
          new_status: params[:status].to_s
        )


        if result.success?
          render json: result.data
        else
          render json: { error: result.error }, status: :unprocessable_entity
        end
      end
    end
  end
end
