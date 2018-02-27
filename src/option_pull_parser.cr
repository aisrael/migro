struct Flag
  getter :name
  def initialize(@name : String)
  end
end

struct FlagWithValue
  getter :name
  getter :value
  def initialize(@name : String, @value : String?)
  end
end

# An OptionPullParser lets you consume command line arguments
# without having to know beforehand all possible options
class OptionPullParser
  @args : Array(String)
  @allowed = [] of AllowedFlag
  getter :args
  getter :allowed

  def initialize(@args = ARGV)
  end

  struct AllowedFlag
    getter :name
    getter :description
    getter :short
    getter :long
    getter :expects_value
    def initialize(@name : String, @description : String?, @short : String?, @long : String?, @expects_value : Bool = false)
    end
    def expects_value?
      @expects_value
    end
  end

  def flag(name : String, short : String? = nil, long : String? = nil, expects_value : Bool = false)
    @allowed << AllowedFlag.new(name, nil, short, long || name, expects_value)
  end

  def empty? : Bool
    @args.empty?
  end

  def read : String | Flag | FlagWithValue | Nil
    return nil if @args.empty?
    arg = convert(@args.shift)
    case arg
    when FlagWithValue
      if arg.value.nil?
        next_token = peek
        case next_token
        when String
          return FlagWithValue.new(arg.name, @args.shift)
        else
          puts "Expecting value for --#{arg.name}"
          exit 1
        end
      end
    end
    arg
  end

  def peek : String | Flag | FlagWithValue | Nil
    return nil if @args.empty?
    convert(@args.first)
  end

  private def convert(s)
    case s
    when /^--(\S+)/ # --long
      raw = $1
      i = raw.index("=")
      if i
        long = raw[0...i]
        value = raw[(i+1)..-1]
      else
        long = raw
      end
      if found = @allowed.find { |af| af.long == long }
        if found.expects_value?
          return FlagWithValue.new(found.name, value)
        else
          return Flag.new(found.name)
        end
      end
    when /^-(\S+)/ # -s or short
      short = $1
      if found = @allowed.find { |af| af.short == short }
        return Flag.new(found.name)
      end
    end
    s
  end
end
