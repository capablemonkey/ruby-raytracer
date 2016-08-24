INFINITY = 1e8

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
    @x = x.to_f
    @y = y.to_f
    @z = z.to_f
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

  def to_s
    "[#{@x}, #{@y}, #{@z}]"
  end

  def normalize
    return copy unless length > 0
    Vec3.new(@x / length, @y / length, @z / length)
  end

  def copy
    Vec3.new(@x, @y, @z)
  end
end

class Sphere
  def initialize(options)
    @center = options.fetch(:center)
    @radius = options.fetch(:radius)
    @surface_color = options.fetch(:surface_color)
    @reflection = options.fetch(:reflection)
    @transparency = options.fetch(:transparency)
    @emission_color = options.fetch(:emission_color, nil)
  end

  attr_reader :center, :radius, :surface_color, :reflection, :transparency, :emission_color

  def light?
    @emission_color.nil?
  end
end

class Ray
  def initialize(params)
    @origin = params.fetch(:origin)
    @direction = params.fetch(:direction)
  end

  attr_reader :origin, :direction

  def trace(spheres)
    tnear = INFINITY
    sphere = nil

    # find intersecting sphere, if exists:

    spheres.each do |s|
      @t0 = INFINITY
      @t1 = INFINITY

      if intersect_sphere?(s)
        @t0 = @t1 if @t0 < 0

        if @t0 < tnear
          tnear = @t0
          sphere = s
        end
      end
    end

    return Vec3.new(0, 0, 0) if sphere.nil?

    # phit = @origin + @direction * tnear

    Vec3.new(255, 255, 255)
  end

  private

    def intersect_sphere?(sphere)
      l = sphere.center - @origin
      tca = l.dot_product(@direction)

      return false if tca < 0

      d2 = l.dot_product(l) - tca ** 2

      return false if d2 > sphere.radius ** 2

      thc = Math.sqrt(sphere.radius ** 2 - d2)
      @t0 = tca - thc
      @t1 = tca + thc

      return true
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
      xx = (2 * ((x + 0.5) / width) - 1) * angle * aspect_ratio
      yy = (1 - 2 * ((y + 0.5) / height)) * angle

      ray = Ray.new(
        :origin => Vec3.new(0, 0, 0),
        :direction => Vec3.new(xx, yy, -1).normalize
      )

      pixel = ray.trace(spheres)
      image.write_pixel(pixel.x.to_i, pixel.y.to_i, pixel.z.to_i)
    end
  end

  image.close
end

def main
  a = Sphere.new(
    :center => Vec3.new(1.0, 0, -50),
    :radius => 2,
    :surface_color => Vec3.new(255, 255, 100),
    :reflection => 1.0,
    :transparency => 0.5
  )

  b = Sphere.new(
    :center => Vec3.new(3.0, 2, -20),
    :radius => 1,
    :surface_color => Vec3.new(255, 255, 100),
    :reflection => 1.0,
    :transparency => 0.5
  )

  render([a, b])
end

main