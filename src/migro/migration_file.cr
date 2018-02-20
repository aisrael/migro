# Holds data about migration files
struct Migro::MigrationFile
  include Comparable(MigrationFile)

  getter :filename
  getter :numeric_prefix
  getter :text
  getter :extension

  @numeric_prefix : String?
  @text : String
  @extension : String?

  def initialize(@filename : String)
    if /^(\d+[-_])?(.+)$/ =~ filename
      prefix = $1?
      suffix = $2
      @numeric_prefix = prefix[0...-1] if prefix
      @extension = suffix.split(".").last
      if @extension
        @text = suffix.chomp(".#{@extension}").not_nil!
      else
        @text = suffix.not_nil!
      end
    else
      raise %(Don't know how to handle migration "#{filename}"!)
    end
  end

  def <=>(other)
    if other.numeric_prefix == @numeric_prefix
      @text <=> other.text
    else
      this_n = @numeric_prefix
      other_n = other.numeric_prefix
      case
      when this_n && other_n
        this_n.to_i64 <=> other_n.to_i64
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
