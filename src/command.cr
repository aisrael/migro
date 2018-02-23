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

abstract class Command

  struct SubCommand
    getter :name, :description, :block
    def initialize(@name : String | Symbol, @description : String, @block : Proc(Nil))
    end
  end

  @@sub_commands = Hash(String, SubCommand).new
  @@allowed = [] of OptionPullParser::AllowedFlag

  def self.short_description(desc : String)
    @@short_description = desc
  end

  def self.version(version : String)
    @@version = version
    command(:version, "Display the program version") do
      puts [@@short_description, "version #{@@version}"].compact.join(", ")
    end
  end

  def self.flag(name : String, description : String, short : String? = nil, long : String? = nil, expects_value : Bool = false)
    @@allowed << OptionPullParser::AllowedFlag.new(name, description, short, long || name, expects_value)
  end

  def self.command(name : String | Symbol, description : String, &block)
    @@sub_commands[name.to_s] = SubCommand.new(name, description, block)
  end

  @@flags = Hash(String, Bool).new
  class_getter :flags

  @@options = Hash(String, String).new
  class_getter :options

  @command : SubCommand?
  @args = [] of String
  getter :args

  def command(name : String | Symbol, description : String, &block)
    @@sub_commands[name.to_s] = SubCommand.new(name, description, block)
  end

  def initialize(@argv : Array(String))
    @opp = OptionPullParser.new(@argv)
    @@allowed.each do |flag|
      @opp.allowed << flag
    end
    command :help, "Prints this help text" do
      puts "#{@@short_description}, version #{@@version}"
      puts <<-HEADER
      Usage:
        migro <command> [flags]

      Commands:
      HEADER
      longest_key = @@sub_commands.keys.map(&.size).max
      @@sub_commands.each do |key, command|
        padding = Array.new(longest_key - key.size, " ").join
        puts "  #{command.name}#{padding} - #{command.description}"
      end
      puts <<-FLAGS

      Flags :
      FLAGS
      longest_flag = @@allowed.map {|f| (f.long || "").size}.max
      @@allowed.each do |flag|
        size = (flag.long || "").size
        padding = Array.new(longest_flag - size, " ").join
        puts "  #{flag.long}#{padding} - #{flag.description}"
      end
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
    command = @command
    if command.nil?
      STDERR.puts %(Don't know how to handle "#{args.join(" ")}")
    else
      return call_with_self(&command.block)
    end
  end

  private def handle_possible_command(key)
    if @command.nil?
      if @@sub_commands.has_key?(key)
        @command =  @@sub_commands[key]
        return
      end
    end
    @args << key
  end

  private def call_with_self(&block)
    with self yield
  end
end
