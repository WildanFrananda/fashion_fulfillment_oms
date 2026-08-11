# typed: strict

module MerchantRepositoryInterface
  extend T::Sig
  extend T::Helpers
  interface!

  sig { abstract.params(id: Integer).returns(T.nilable(Merchant)) }
  def find_by_id(id); end

  sig { abstract.params(api_key: String).returns(T.nilable(Merchant)) }
  def find_by_api_key(api_key); end
end
