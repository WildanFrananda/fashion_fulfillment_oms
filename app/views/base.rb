# typed: strict
# frozen_string_literal: true

module Views
  class Base < Components::Base
    extend T::Sig

    sig { returns(ActiveSupport::Cache::Store) }
    def cache_store
      Rails.cache
    end
  end
end
