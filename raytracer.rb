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

class Vec3
  def initialize(x, y, z)
    @x = x
    @y = y
    @z = z
  end

  attr_reader :x, :y, :z

  def *(other)
    if other.respond_to?(:x)
      Vec3.new(@x * other.x, @y * other.y, @z * other.z)
    else
      Vec3.new(@x * other, @y * other, @z * other)
    end
  end

  def dot_product(other)
    @x * other.x + @y * other.y + @z * other.z
  end

  def +(other)
    Vec3.new(@x + other.x, @y + other.y, @z + other.z)
  end

  def -(other)
    Vec3.new(@x - other.x, @y - other.y, @z - other.z)
  end

  def increment_by(other)
    @x += other.x
    @y += other.y
    @z += other.z
    self
  end

  def decrement_by(other)
    @x -= other.x
    @y -= other.y
    @z -= other.z
    self
  end

  def length_squared
    @x ** 2 + @y ** 2 + @z ** 2
  end

  def length
    Math.sqrt(length_squared)
  end

  def inspect
    "[#{@x}, #{@y}, #{@z}]"
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