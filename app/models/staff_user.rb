# typed: strict

class StaffUser < ApplicationRecord
  extend T::Sig

  belongs_to :merchant

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :role, presence: true
end
