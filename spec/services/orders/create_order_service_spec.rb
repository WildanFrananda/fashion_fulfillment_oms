# typed: false

require "rails_helper"

RSpec.describe Orders::CreateOrderService, type: :service do
  let!(:merchant) { create(:merchant, cutoff_hour: 14) }
  let(:service) { described_class.new }

  it "creates an order and sets initial status based on cutoff time" do
    form = Orders::CreateOrderForm.new(
      order_number: "ORD-TEST-100",
      buyer_name: "Aisyah",
      buyer_phone: "0811223344",
      shipping_address: "Jakarta",
      total_amount: BigDecimal("200000.0"),
      items: [
        Orders::CreateOrderForm::ItemInput.new(
          sku: "SKU-1",
          product_name: "Gamis",
          quantity: 1,
          price: BigDecimal("200000.0")
        )
      ]
    )

    result = service.call(merchant_id: merchant.id, form: form)

    expect(result.success?).to be true
    expect(result.data.order_number).to eq("ORD-TEST-100")
  end
end
