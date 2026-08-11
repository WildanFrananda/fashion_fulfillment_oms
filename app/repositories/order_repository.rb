# typed: strict

class OrderRepository < BaseRepository
  include OrderRepositoryInterface
  extend T::Sig

  sig { void }
  def initialize
    super(Order)
  end

  sig { override.params(merchant_id: Integer, id: Integer).returns(T.nilable(Order)) }
  def find_by_id(merchant_id:, id:)
    T.cast(model.find_by(merchant_id: merchant_id, id: id), T.nilable(Order))
  end

  sig { override.params(merchant_id: Integer, order_number: String).returns(T.nilable(Order)) }
  def find_by_order_number(merchant_id:, order_number:)
    T.cast(model.find_by(merchant_id: merchant_id, order_number: order_number), T.nilable(Order))
  end

  sig { override.params(merchant_id: Integer, attributes: T::Hash[Symbol, T.anything]).returns(Order) }
  def create(merchant_id:, attributes:)
    T.cast(model.create!(attributes.merge(merchant_id: merchant_id)), Order)
  end

  sig { override.params(merchant_id: Integer).returns(T::Array[Order]) }
  def due_today(merchant_id:)
    T.cast(model.where(merchant_id: merchant_id).order(same_day_cutoff_at: :asc).to_a, T::Array[Order])
  end

  sig { override.params(merchant_id: Integer, order_id: Integer, status: String).returns(T.nilable(Order)) }
  def update_status(merchant_id:, order_id:, status:)
    order = find_by_id(merchant_id: merchant_id, id: order_id)
    return nil unless order

    order.update!(status: status)
    order
  end
end
