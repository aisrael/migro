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

    @@SubCommandDecls = {} of String => SubCommandDecl

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
      @@SubCommandDecls[name.to_s] = sub
      @@SubCommandDecls[aliaz.to_s] = sub if aliaz
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

    private def handle_possible_command(key)
      if @command.nil?
        if @@SubCommandDecls.has_key?(key)
          return @command = @@SubCommandDecls[key]
        end
      end
      @args << key
   end
  end
end
