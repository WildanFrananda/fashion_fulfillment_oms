# typed: strict

class Return < ApplicationRecord
  extend T::Sig

  belongs_to :merchant
  belongs_to :order

  validates :reason, presence: true
  validates :status, presence: true
end
