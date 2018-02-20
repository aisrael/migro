# An IO decorator that wraps another underlying IO, and
# performs Digest computation while reading/writing.
#
# ```
#   File.open("file").do |file|
#     dio = DigestIO.md5()
class DigestIO < IO
  def initialize(@digest : Digest::Base, io : IO)
    @io = io.is_a?(IO::Buffered) ? io : IO::Buffered.new(io)
  end

  # Creates a DigestIO decorator using the `Digest::MD5` digest
  def self.md5(io : IO)
    DigestIO.new(Digest::MD5.new, io)
  end

  # See [IO#read](https://crystal-lang.org/api/0.24.1/IO.html#read%28slice%3ABytes%29-instance-method)
  def read(slice)
    read = @io.read(slice)
    @digest.update(slice.to_unsafe, read)
    read
  end

  # See [IO#write](https://crystal-lang.org/api/0.24.1/IO.html#write%28slice%3ABytes%29%3ANil-instance-method)
  def write(slice)
    @digest.update(slice)
    @io.write(slice)
  end

  # Calls `#final` on the underlying digest and returs the result as
  # hexadecimal string
  def hexdigest
    @digest.final
    @digest.result.to_slice.hexstring
  end
end
