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

def test_image
  image = Image.new('out.ppm', 255, 255)

  0.upto(100) do |y|
    0.upto(254) do |x|
      image.write_pixel(255, 255, 0)
    end
  end

  0.upto(154) do |y|
    0.upto(254) do |x|
      image.write_pixel(0, 255, 0)
    end
  end

  image.close
end

def main
  test_image
end

main