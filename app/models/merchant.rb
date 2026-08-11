# typed: strict

class Merchant < ApplicationRecord
  extend T::Sig

  has_many :staff_users, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :returns, dependent: :destroy

  validates :name, presence: true
  validates :code, presence: true, uniqueness: true
  validates :api_key, presence: true, uniqueness: true
  validates :cutoff_hour, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 23 }
end
