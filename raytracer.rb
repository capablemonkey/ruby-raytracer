require_relative 'lib/vec3.rb'
require_relative 'lib/sphere.rb'
require_relative 'lib/image.rb'
require_relative 'lib/ray.rb'

class Renderer
  def initialize
    @width = 320
    @height = 240
    @fov = 30
    @aspect_ratio = @width.to_f / @height
    @angle = Math.tan(Math::PI * 0.5 * @fov / 180)
  end

  def render(spheres)
    image = Image.new('out.ppm', @width, @height)

    @height.times do |y|
      @width.times do |x|
        xx = (2 * ((x + 0.5) / @width) - 1) * @angle * @aspect_ratio
        yy = (1 - 2 * ((y + 0.5) / @height)) * @angle

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
end

def main
  bg = Sphere.new(
    :center => Vec3.new(0, -10004, -20),
    :radius => 10000,
    :surface_color => Vec3.new(0.2, 0.2, 0.2),
    :reflection => 0,
    :transparency => 0
  )

  a = Sphere.new(
    :center => Vec3.new(0, 0, -20),
    :radius => 2,
    :surface_color => Vec3.new(1.00, 0.32, 0.36),
    :reflection => 1,
    :transparency => 0.5
  )

  b = Sphere.new(
    :center => Vec3.new(5.0, -1.0, -15),
    :radius => 2,
    :surface_color => Vec3.new(0.90, 0.76, 0.46),
    :reflection => 1,
    :transparency => 0
  )

  c = Sphere.new(
    :center => Vec3.new(5.0, 0, -25),
    :radius => 3,
    :surface_color => Vec3.new(0.65, 0.77, 0.97),
    :reflection => 1,
    :transparency => 0
  )

  d = Sphere.new(
    :center => Vec3.new(-5.5, 0, -15),
    :radius => 3,
    :surface_color => Vec3.new(0.9, 0.9, 0.9),
    :reflection => 1,
    :transparency => 0
  )

  light = Sphere.new(
    :center => Vec3.new(0, 20, -30),
    :radius => 3,
    :surface_color => Vec3.new(0, 0, 0),
    :reflection => 0,
    :transparency => 0,
    :emission_color => Vec3.new(3, 3, 3)
  )

  Renderer.new.render([a, b, c, d, bg, light])
end

main