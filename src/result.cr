abstract struct Result(T)
  def self.success(value : T)
    Success.new(value)
  end

  def self.failure(message_or_exception : String | Exception) forall T
    Failure(T).new(message_or_exception)
  end

  abstract def then(&block : T -> Result(T))
  abstract def else(&block : -> Result(T))
end

struct Failure(T) < Result(T)
  def initialize(@message_or_exception : String | Exception)
  end

  def message : String
    moe = @message_or_exception
    return moe if moe.is_a?(String)
    message = moe.message
    if !message.nil?
      message.not_nil!
    else
      moe.to_s
    end
  end

  def then(&block : T -> Result(T))
    self
  end

  def else(&block : -> Result(T))
    yield
  end
end

struct Success(T) < Result(T)
  getter :value

  def initialize(@value : T)
  end

  def then(&block : T -> Result(T))
    yield @value
  end

  def else(&block : -> Result(T))
    self
  end
end
