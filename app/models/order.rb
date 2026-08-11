# typed: strict

class Order < ApplicationRecord
  extend T::Sig

  belongs_to :merchant
  has_many :order_items, dependent: :destroy
  has_one :shipping_label, dependent: :destroy
  has_one :return_request, class_name: "Return", dependent: :destroy

  validates :order_number, presence: true, uniqueness: true
  validates :status, presence: true
  validates :same_day_cutoff_at, presence: true
end
