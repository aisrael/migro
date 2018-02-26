require "./option_pull_parser"

struct SubCommand
  getter :name, :clazz, :description
  def initialize(@name : String, @clazz : Command.class, @description : String)
  end
end

abstract class Command

  def args : Array(String)
    [] of String
  end

  def options : Hash(String, String)
    {} of String => String
  end

  def initialize
  end

  abstract def run

  class Main

    @@subcommands = {} of String => SubCommand

    def self.command(**args)
      name, clazz = args.to_a.first
      raise "clazz is a #{clazz.class}, expecting Class" if clazz.is_a?(String)
      command(name.to_s, clazz, args[:description] || name.to_s)
    end

    def self.command(name : String, clazz : C, description : String) forall C
      p name: name
      p clazz: clazz
      sub = SubCommand.new(name, clazz, description)
      @@subcommands[name.to_s] = sub
    end

    def self.run
      self.new(OptionPullParser.new(ARGV)).run
    end

    @opp : OptionPullParser
    @args = [] of String
    @flags = Hash(String, Bool).new
    @options = Hash(String, String).new
    @command : SubCommand?
    getter :args, :flags, :options

    def initialize(@opp : OptionPullParser)
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
      p cmd: cmd
      if cmd.nil?
        STDERR.puts %(Don't know how to handle "#{args.join(" ")}")
      else
        p args: args
        clazz = cmd.clazz
        p clazz: clazz
        clazz.new.run
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
