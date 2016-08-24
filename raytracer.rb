INFINITY = 1e8
MAX_RAY_DEPTH = 5

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

# Represents 3 component vector and RGB ratio values
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

  def to_rgb
    [
      ([1.0, @x].min * 255).to_i,
      ([1.0, @y].min * 255).to_i,
      ([1.0, @z].min * 255).to_i
    ]
  end
end

class Sphere
  def initialize(options)
    @center = options.fetch(:center)
    @radius = options.fetch(:radius)
    @surface_color = options.fetch(:surface_color)
    @reflection = options.fetch(:reflection)
    @transparency = options.fetch(:transparency)
    @emission_color = options.fetch(:emission_color, Vec3.new(0, 0, 0))
  end

  attr_reader :center, :radius, :surface_color, :reflection, :transparency, :emission_color

  def light?
    @emission_color.x > 0 || @emission_color.y > 0 || @emission_color.z > 0
  end

  def transparent?
    @transparency > 0
  end

  def reflective?
    @reflection > 0
  end
end

class Ray
  def initialize(params)
    @origin = params.fetch(:origin)
    @direction = params.fetch(:direction)
  end

  attr_reader :origin, :direction

  def trace(spheres, depth)
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

    surface_color = Vec3.new(0, 0, 0)
    phit = @origin + @direction * tnear
    nhit = phit - sphere.center
    nhit = nhit.normalize

    bias = 1e-4
    inside = false

    if @direction.dot_product(nhit) > 0
      nhit = nhit * -1
      inside = true
    end

    if (sphere.transparent? || sphere.reflective?) && (depth < MAX_RAY_DEPTH)
      facing_ratio = @direction.dot_product(nhit) * -1 # TODO: possible order of ops issue with -raydir
      fresnel_effect = mix((1 - facing_ratio) ** 3, 1, 0.1)

      # compute reflection direction
      reflection_direction = @direction - nhit * 2 * @direction.dot_product(nhit)
      reflection_direction = reflection_direction.normalize

      reflection_ray = Ray.new(
        :origin => phit + nhit * bias,
        :direction => reflection_direction
      )

      reflection = reflection_ray.trace(spheres, depth + 1)

      # calculate refraction
      refraction = Vec3.new(0, 0, 0)

      if sphere.transparent?
        ior = 1.1
        eta = inside ? ior : (1 / ior)
        cosi = nhit.dot_product(@direction) # TODO: possible order of ops issue with -nhit
        k = 1 - eta * eta * (1 - cosi ** 2)

        refraction_direction = @direction * eta + nhit * (eta * cosi - Math.sqrt(k))
        refraction_direction = refraction_direction.normalize
        refraction_ray = Ray.new(
          :origin => phit - nhit * bias,
          :direction => refraction_direction
        )

        refraction = refraction_ray.trace(spheres, depth + 1)
      end

      surface_color = sphere.surface_color * (
        reflection * fresnel_effect +
        refraction * (1 - fresnel_effect) * sphere.transparency)
    else
      spheres.each do |s|
        if s.light?
          transmission = Vec3.new(1, 1, 1)
          light_direction = s.center - phit
          light_direction = light_direction.normalize

          spheres.each do |k|
            if k != s
              @t0 = nil
              @t1 = nil

              new_ray = Ray.new(
                :origin => phit + nhit * bias,
                :direction => light_direction
              )

              if new_ray.intersect_sphere?(k)
                transmission = 0
                break
              end
            end
          end

          surface_color += sphere.surface_color * transmission * [0, nhit.dot_product(light_direction)].max * sphere.emission_color
        end
      end
    end

    surface_color + sphere.emission_color
  end

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

  private

    def mix(a, b, mix)
      b * mix + a * (1 - mix)
    end
end

def render(spheres)
  width = 255
  height = 255
  fov = 30
  aspect_ratio = width.to_f / height
  angle = Math.tan(Math::PI * 0.5 * fov / 180)

  image = Image.new('out.ppm', width, height)

  height.times do |y|
    width.times do |x|
      xx = (2 * ((x + 0.5) / width) - 1) * angle * aspect_ratio
      yy = (1 - 2 * ((y + 0.5) / height)) * angle

      ray = Ray.new(
        :origin => Vec3.new(0, 0, 0),
        :direction => Vec3.new(xx, yy, -1).normalize
      )

      pixel = ray.trace(spheres, 0)
      image.write_pixel(*pixel.to_rgb)
    end
  end

  image.close
end

def main
  a = Sphere.new(
    :center => Vec3.new(1.0, 0, -20),
    :radius => 2,
    :surface_color => Vec3.new(0.90, 0.76, 0.46),
    :reflection => 1,
    :transparency => 1
  )

  b = Sphere.new(
    :center => Vec3.new(-2.0, -1, -15),
    :radius => 1,
    :surface_color => Vec3.new(0.20, 0.16, 0.46),
    :reflection => 1,
    :transparency => 1
  )

  light = Sphere.new(
    :center => Vec3.new(0, 2, -30),
    :radius => 3,
    :surface_color => Vec3.new(0, 0, 0),
    :reflection => 0,
    :transparency => 0,
    :emission_color => Vec3.new(3, 3, 3)
  )

  bg = Sphere.new(
    :center => Vec3.new(0, -10000, -20),
    :radius => 10000,
    :surface_color => Vec3.new(0.2, 0.2, 0.2),
    :reflection => 0,
    :transparency => 0
  )

  render([a, b, light])
end

main