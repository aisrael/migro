require "./option_pull_parser"

struct SubCommandDecl
  getter :name, :clazz, :description, :alias
  def initialize(@name : String, @clazz : ::Command.class, @description : String, @alias : String? = nil)
  end
end

abstract class Command

  def args : Array(String)
    [] of String
  end

  def options : Hash(String, String)
    {} of String => String
  end

  getter :parent

  def initialize(@parent : Command?)
  end

  abstract def run

  class Main < Command

    @@subcommands = {} of String => SubCommandDecl
    class_getter :subcommands
    def subcommands
      @@subcommands
    end

    @@allowed = [] of OptionPullParser::AllowedFlag
    class_getter :allowed
    def self.flag(name : String, description : String, expects_value : Bool? = false)
      @@allowed << OptionPullParser::AllowedFlag.new(name, description, nil, name, expects_value)
    end
    def allowed
      @@allowed
    end

    @@short_description : String? = nil
    class_getter :short_description
    def short_description : String?
      @@short_description
    end
    def self.short_description(description : String)
      @@short_description = description
    end

    @@version : String? = nil
    class_getter :version
    def version : String?
      @@version
    end
    class Version < Command
      def run
        if !parent.nil? && parent.is_a?(Command::Main)
          main = parent.as(Command::Main)
          puts [main.short_description, main.version].compact.join(", ")
        end
      end
    end
    def self.version(v : String)
      @@version = v
      command("version", Version, "displays the program version")
    end

    def self.command(**args)
      name, clazz = args.to_a.first
      raise "clazz is a #{clazz.class}, expecting Class" if clazz.is_a?(String)
      command(name.to_s, clazz, args[:description] || name.to_s, args[:alias]?)
    end

    def self.command(name : String, clazz : C, description : String, alias aliaz : String? = nil) forall C
      sub = SubCommandDecl.new(name, clazz, description, aliaz)
      @@subcommands[name.to_s] = sub
      @@subcommands[aliaz.to_s] = sub if aliaz
    end

    def self.run
      self.new(nil).run
    end

    @opp : OptionPullParser
    @args = [] of String
    @flags = Hash(String, Bool).new
    @options = Hash(String, String).new
    @command : SubCommandDecl?
    getter :args, :flags, :options

    def initialize(@parent : Command?)
      @opp = OptionPullParser.new(ARGV)
      self.class.command "help", Help, "Prints this help text"
    end

    def run
      while o = @opp.read
        case o
        when Flag
          @flags[o.name] = true
        when FlagWithValue
          @options[o.name] = o.value.not_nil! unless o.value.nil?
        else
          handle_possible_command(o)
        end
      end
      cmd = @command
      if cmd.nil?
        STDERR.puts %(Don't know how to handle "#{args.join(" ")}")
      else
        clazz = cmd.clazz
        clazz.new(self).run
      end
    end

    class Help < Command
      def run
        if !parent.nil? && parent.is_a?(Command::Main)
          main = parent.as(Command::Main)
          puts "#{main.short_description}, version #{main.version}"
          puts <<-HEADER
          Usage:
            migro <command> [flags]

          Commands:
          HEADER
          subcommands = main.class.subcommands.values.uniq
          longest_key = subcommands.map(&.name.size).max
          subcommands.each do |command|
            padding = Array.new(longest_key - command.name.size, " ").join
            puts "  #{command.name}#{padding} - #{command.description}"
          end
          puts <<-FLAGS

          Flags :
          FLAGS
          allowed = main.class.allowed
          longest_flag = allowed.map {|f| (f.long || "").size}.max
          allowed.each do |flag|
            size = (flag.long || "").size
            padding = Array.new(longest_flag - size, " ").join
            puts "  --#{flag.long}#{padding} - #{flag.description}"
          end
        end
      end
    end

    private def handle_possible_command(key)
      if @command.nil?
        if @@subcommands.has_key?(key)
          return @command = @@subcommands[key]
        end
      end
      @args << key
   end
  end
end