class Image
  def initialize(filename, width, height)
    @file = File.open(filename, 'w')
    @width = width
    @height = height
    @cursor_x = 0

    write_header
  end

  def write_pixel(r, g, b)
    @file.write("#{r} #{g} #{b} ")
    @cursor_x += 1

    if @cursor_x == @width
      @file.write("\n")
      @cursor_x = 0
    end
  end

  def close
    @file.close
  end

  private

    def write_header
      @file.write("P3\n#{@width}\n#{@height}\n255\n")
    end
end