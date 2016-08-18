class Image
  def initialize
    @file = File.open('out.ppm', 'w')
    @cursor_x = 0

    write_header
  end

  def write_pixel(r, g, b)
    @file.write("#{r} #{g} #{b} ")
    @cursor_x += 1

    if @cursor_x == 255
      @file.write("\n")
      @cursor_x = 0
    end
  end

  def close
    @file.close
  end

  private

    def write_header
      @file.write("P3\n255\n255\n255\n")
    end
end

def main
  image = Image.new

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

main