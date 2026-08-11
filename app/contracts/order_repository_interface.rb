# typed: strict

module OrderRepositoryInterface
  extend T::Sig
  extend T::Helpers
  interface!

  sig { abstract.params(merchant_id: Integer, id: Integer).returns(T.nilable(Order)) }
  def find_by_id(merchant_id:, id:); end

  sig { abstract.params(merchant_id: Integer, order_number: String).returns(T.nilable(Order)) }
  def find_by_order_number(merchant_id:, order_number:); end

  sig { abstract.params(merchant_id: Integer, attributes: T::Hash[Symbol, T.anything]).returns(Order) }
  def create(merchant_id:, attributes:); end

  sig { abstract.params(merchant_id: Integer).returns(T::Array[Order]) }
  def due_today(merchant_id:); end

  sig { abstract.params(merchant_id: Integer, order_id: Integer, status: String).returns(T.nilable(Order)) }
  def update_status(merchant_id:, order_id:, status:); end
end
