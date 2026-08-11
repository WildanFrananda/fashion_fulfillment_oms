# typed: strict

class OrderItem < ApplicationRecord
  extend T::Sig

  belongs_to :order

  validates :sku, presence: true
  validates :product_name, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
