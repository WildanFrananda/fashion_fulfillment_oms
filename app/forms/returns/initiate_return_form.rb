# typed: strict

module Returns
  class InitiateReturnForm
    extend T::Sig

    sig { returns(Integer) }
    attr_reader :order_id

    sig { returns(String) }
    attr_reader :reason

    sig { returns(T::Array[String]) }
    attr_reader :errors

    sig { params(order_id: Integer, reason: String).void }
    def initialize(order_id:, reason:)
      @order_id = order_id
      @reason = reason
      @errors = T.let([], T::Array[String])
    end

    sig { returns(T::Boolean) }
    def valid?
      @errors.clear
      @errors << "Order ID must be positive" if @order_id <= 0
      @errors << "Reason cannot be blank" if @reason.strip.empty?
      @errors.empty?
    end
  end
end
