# typed: strict

module Orders
  class CreateOrderForm
    extend T::Sig

    class ItemInput < T::Struct
      const :sku, String
      const :product_name, String
      const :quantity, Integer
      const :price, BigDecimal
    end

    sig { returns(String) }
    attr_reader :order_number

    sig { returns(String) }
    attr_reader :buyer_name

    sig { returns(String) }
    attr_reader :buyer_phone

    sig { returns(String) }
    attr_reader :shipping_address

    sig { returns(BigDecimal) }
    attr_reader :total_amount

    sig { returns(T::Array[ItemInput]) }
    attr_reader :items

    sig { returns(T::Array[String]) }
    attr_reader :errors

    sig do
      params(
        order_number: String,
        buyer_name: String,
        buyer_phone: String,
        shipping_address: String,
        total_amount: BigDecimal,
        items: T::Array[ItemInput]
      ).void
    end

    def initialize(order_number:, buyer_name:, buyer_phone:, shipping_address:, total_amount:, items:)
      @order_number = order_number
      @buyer_name = buyer_name
      @buyer_phone = buyer_phone
      @shipping_address = shipping_address
      @total_amount = total_amount
      @items = items
      @errors = T.let([], T::Array[String])
    end

    sig { returns(T::Boolean) }
    def valid?
      @errors.clear
      @errors << "Order number cannot be blank" if @order_number.strip.empty?
      @errors << "Buyer name cannot be blank" if @buyer_name.strip.empty?
      @errors << "Shipping address cannot be blank" if @shipping_address.strip.empty?
      @errors << "Items list cannot be empty" if @items.empty?
      @errors.empty?
    end
  end
end
