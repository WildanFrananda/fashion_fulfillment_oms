# typed: strict

class HealthController < ApplicationController
  extend T::Sig

  sig { void }
  def show
    db_healthy = begin
      ActiveRecord::Base.connection.execute("SELECT 1")
      true
    rescue StandardError
      false
    end

    if db_healthy
      render json: { status: "ok", database: "connected", timestamp: Time.current.iso8601 }
    else
      render json: { status: "error", database: "disconnected", timestamp: Time.current.iso8601 }, status: :service_unavailable
    end
  end
end
