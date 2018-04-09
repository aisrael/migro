# Holds data about migration files
struct Migro::MigrationFile
  include Comparable(MigrationFile)

  getter :filename
  getter :numeric_prefix
  getter :text
  getter :extension

  @numeric_prefix : String?
  @text : String?
  @extension : String?

  def initialize(filename : String)
    @filename = filename
    @extension = File.extname(filename)[1..-1]
    basename = if i = filename.rindex(".")
      filename[0...i]
    else
      filename
    end
    if /^(\d+)/ =~ basename
      prefix = $1.not_nil!
      @numeric_prefix = prefix
      if prefix.size + 1 < basename.size
        @text = basename[(prefix.size + 1)..-1]
      end
    else
      @text = basename
    end
  end

  def <=>(other)
    this_n = @numeric_prefix
    other_n = other.numeric_prefix
    if this_n == other_n
      this_text = @text
      other_text = other.text
      case
      when this_text && other_text
        this_text <=> other_text
      when this_text
        1
      when other_text
        -1
      else
        0
      end
    else
      case
      when this_n && other_n
        this_i = this_n.to_i64
        other_i = other_n.to_i64
        # if the numeric prefixes are numerically equal
        if this_i == other_i
          # treat as strings again
          this_n <=> other_n
        else
          this_i <=> other_i
        end
      when this_n
        1
      when other_n
        -1
      else
        0
      end
    end
  end
end
