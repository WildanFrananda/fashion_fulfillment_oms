# typed: strict

class BaseService
  extend T::Sig

  class Result < T::Struct
    extend T::Sig

    const :success, T::Boolean
    const :data, T.nilable(T.anything)
    const :error, T.nilable(String)

    sig { returns(T::Boolean) }
    def success?
      success
    end


    sig { returns(T::Boolean) }
    def failure?
      !success
    end
  end

  protected

  sig { params(data: T.anything).returns(Result) }
  def success(data)
    Result.new(success: true, data: data, error: nil)
  end

  sig { params(error: String).returns(Result) }
  def failure(error)
    Result.new(success: false, data: nil, error: error)
  end
end
