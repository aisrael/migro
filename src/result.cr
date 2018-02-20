abstract struct Result(T)
  def self.success(value : T)
    Success.new(value)
  end
  def self.failure(message : String)
    Failure(T).new(message)
  end
end

struct Failure(T) < Result(T)
  getter :message
  def initialize(@message : String)
  end
end

struct Success(T) < Result(T)
  getter :value
  def initialize(@value : T)
  end
end
