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
    getter :short
    getter :long
    getter :expects_value
    def initialize(@name : String, @short : String?, @long : String?, @expects_value : Bool = false)
    end
    def expects_value?
      @expects_value
    end
  end

  def flag(name : String, short : String? = nil, long : String? = nil, expects_value : Bool = false)
    @allowed << AllowedFlag.new(name, short, long || name, expects_value)
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

abstract class Command
  @@commands = Hash(String | Symbol, Proc(Nil)).new
  @@allowed = [] of OptionPullParser::AllowedFlag

  def self.short_description(desc : String)
    @@short_description = desc
  end

  def self.version(version : String)
    @@version = version
    command(:version) do
      puts [@@short_description, "version #{@@version}"].compact.join(", ")
    end
  end

  def self.flag(name : String, short : String? = nil, long : String? = nil, expects_value : Bool = false)
    @@allowed << OptionPullParser::AllowedFlag.new(name, short, long || name, expects_value)
  end

  def self.command(name : String | Symbol, &block)
    @@commands[name] = block
  end

  @@flags = Hash(String, Bool).new
  class_getter :flags

  @@options = Hash(String, String).new
  class_getter :options

  @command : (String | Symbol | Nil) = nil
  @args = [] of String
  getter :args

  def initialize(@argv : Array(String))
    @opp = OptionPullParser.new(@argv)
    @@allowed.each do |flag|
      @opp.allowed << flag
    end
  end

  def self.run
    self.new(ARGV).run
  end

  def run
    while o = @opp.read
      case o
      when Flag
        @@flags[o.name] = true
      when FlagWithValue
        @@options[o.name] = o.value.not_nil! unless o.value.nil?
      else
        handle_possible_command(o)
      end
    end
    if @command
      bl = @@commands[@command]
      return call_with_self(&bl)
    end
  end

  private def handle_possible_command(o)
    if @command.nil?
      key = o.to_s
      stringified_keys = @@commands.keys.map(&.to_s)
      if stringified_keys.includes?(key)
        i = stringified_keys.index(key).not_nil!
        @command =  @@commands.keys[i]
        return
      end
    end
    @args << o
  end

  private def call_with_self(&block)
    with self yield
  end

  def read
    @opp.read
  end
end
