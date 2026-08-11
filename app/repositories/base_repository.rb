# typed: strict

class BaseRepository
  extend T::Sig

  sig { returns(T.class_of(ActiveRecord::Base)) }
  attr_reader :model

  sig { params(model: T.class_of(ActiveRecord::Base)).void }
  def initialize(model)
    @model = T.let(model, T.class_of(ActiveRecord::Base))
  end
end
