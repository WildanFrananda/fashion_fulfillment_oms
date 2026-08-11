# typed: strict

class MerchantRepository < BaseRepository
  include MerchantRepositoryInterface
  extend T::Sig

  sig { void }
  def initialize
    super(Merchant)
  end

  sig { override.params(id: Integer).returns(T.nilable(Merchant)) }
  def find_by_id(id)
    T.cast(model.find_by(id: id), T.nilable(Merchant))
  end

  sig { override.params(api_key: String).returns(T.nilable(Merchant)) }
  def find_by_api_key(api_key)
    T.cast(model.find_by(api_key: api_key), T.nilable(Merchant))
  end
end
