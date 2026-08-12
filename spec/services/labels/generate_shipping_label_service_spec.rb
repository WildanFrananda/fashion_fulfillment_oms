# typed: false

require 'rails_helper'

RSpec.describe Labels::GenerateShippingLabelService, type: :service do
  let!(:merchant) { create(:merchant) }
  let!(:order) { create(:order, merchant: merchant) }
  let(:service) { described_class.new }

  it "generates AWB shipping label on first call and increments reprint_count on second call" do
    result1 = service.call(merchant_id: merchant.id, order_id: order.id)
    expect(result1.success?).to be true
    expect(result1.data.reprint_count).to eq(1)

    result2 = service.call(merchant_id: merchant.id, order_id: order.id)
    expect(result2.success?).to be true
    expect(result2.data.reprint_count).to eq(2)
  end
end
