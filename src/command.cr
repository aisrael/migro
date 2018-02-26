require "./option_pull_parser"

struct SubCommandDecl
  getter :name, :clazz, :description
  def initialize(@name : String, @clazz : ::Command.class, @description : String)
  end
end

abstract class Command

  def args : Array(String)
    [] of String
  end

  def options : Hash(String, String)
    {} of String => String
  end

  def initialize(@parent : Command?)
  end

  abstract def run

  class Main < Command

    @@SubCommandDecls = {} of String => SubCommandDecl

    def self.command(**args)
      name, clazz = args.to_a.first
      puts "clazz => #{clazz} (#{clazz.class})"
      raise "clazz is a #{clazz.class}, expecting Class" if clazz.is_a?(String)
      command(name.to_s, clazz, args[:description] || name.to_s)
    end

    def self.command(name : String, clazz : C, description : String) forall C
      p name: name
      p clazz: clazz
      sub = SubCommandDecl.new(name, clazz, description)
      @@SubCommandDecls[name.to_s] = sub
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
      p cmd: cmd
      if cmd.nil?
        STDERR.puts %(Don't know how to handle "#{args.join(" ")}")
      else
        p args: args
        clazz = cmd.clazz
        p clazz: clazz
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
