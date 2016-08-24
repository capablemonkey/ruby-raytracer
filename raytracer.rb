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

class Sphere
  def initialize(center, radius, surface_color, reflection = 0, transparency = 0, emission_color = Vec3.new(0,0,0))
    @center = center
    @radius = radius
    @surface_color = surface_color
    @reflection = reflection
    @transparency = transparency
    @emission_color = emission_color
  end

  # def intersect(ray, t0, t1)
    
  # end
  
  def intersect?(x, y)
    distance = Math.sqrt((@center.x - x) ** 2 + (@center.y - y) ** 2)

    distance <= @radius
  end
end

class Ray
  def initialize(params)
    @origin = params.fetch(:origin)
    @direction = params.fetch(:direction)
  end

  def trace(spheres)
    intersection = spheres.select {|s| s.intersect?(@origin.x, @origin.y)}

    if intersection.empty?
      pixel = Vec3.new(0, 0, 0)
    else
      pixel = Vec3.new(255, 255, 255)
    end

    pixel
  end
end

def render(spheres)
  width = 255
  height = 255
  fov = 30
  aspect_ratio = width.to_f / height
  angle = Math.tan(Math::PI * 0.5 * fov / 180)

  image = Image.new('out.ppm', 255, 255)

  height.times do |y|
    width.times do |x|
      ray = Ray.new(:origin => Vec3.new(x, y, -1), :direction => nil)
      pixel = ray.trace(spheres)
      image.write_pixel(pixel.x, pixel.y, pixel.z)
    end
  end

  image.close
end

def test_image
  image = Image.new('test.ppm', 255, 255)

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

  # TODO: refactor sphere to take params as hash
  a = Sphere.new(Vec3.new(0, 0, 0), 50, Vec3.new(255, 255, 100), 1.0, 0.5)
  b = Sphere.new(Vec3.new(100, 100, 0), 20, Vec3.new(255, 255, 100), 1.0, 0.5)
  render([a, b])
end

main