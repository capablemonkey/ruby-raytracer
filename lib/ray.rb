INFINITY = 1e8
MAX_RAY_DEPTH = 5
BIAS = 1e-4

class Ray
  def initialize(params)
    @origin = params.fetch(:origin)
    @direction = params.fetch(:direction)
  end

  attr_reader :origin, :direction

  def trace(spheres, depth)
    @tnear = INFINITY
    @sphere = nil

    find_intersection(spheres)
    return Vec3.new(2, 2, 2) if @sphere.nil?

    @surface_color = Vec3.new(0, 0, 0)
    @point_of_intersection = @origin + @direction * @tnear
    @normal_at_intersection = (@point_of_intersection - @sphere.center).normalize

    @inside = false

    if @direction.dot_product(@normal_at_intersection) > 0
      @normal_at_intersection = @normal_at_intersection * -1
      @inside = true
    end

    if (@sphere.transparent? || @sphere.reflective?) && (depth < MAX_RAY_DEPTH)
      reflection = calculate_reflection(spheres, depth)
      refraction = @sphere.transparent? ? calculate_refraction(spheres, depth) : Vec3.new(0, 0, 0)

      @surface_color = @sphere.surface_color * (
        reflection * @fresnel_effect +
        refraction * (1 - @fresnel_effect) * @sphere.transparency)
    else
      calculate_diffuse(spheres)
    end

    @surface_color + @sphere.emission_color
  end

  def intersects_sphere?(sphere)
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

  def find_intersection(spheres)
    spheres.each do |s|
      @t0 = INFINITY
      @t1 = INFINITY

      if intersects_sphere?(s)
        @t0 = @t1 if @t0 < 0

        if @t0 < @tnear
          @tnear = @t0
          @sphere = s
        end
      end
    end
  end

  private

    def calculate_diffuse(spheres)
      # this is a diffuse object
      spheres.each do |s|
        if s.light?
          transmission = Vec3.new(1, 1, 1)
          light_direction = s.center - @point_of_intersection
          light_direction = light_direction.normalize

          spheres.each do |k|
            if k != s
              @t0 = nil
              @t1 = nil

              new_ray = Ray.new(
                :origin => @point_of_intersection + @normal_at_intersection * BIAS,
                :direction => light_direction
              )

              if new_ray.intersects_sphere?(k)
                transmission = 0
                break
              end
            end
          end

          @surface_color += @sphere.surface_color * transmission * [0, @normal_at_intersection.dot_product(light_direction)].max * s.emission_color
        end
      end
    end

    def calculate_reflection(spheres, depth)
      facing_ratio = @direction.dot_product(@normal_at_intersection) * -1
      @fresnel_effect = mix((1 - facing_ratio) ** 3, 1, 0.1)

      reflection_ray = Ray.new(
        :origin => @point_of_intersection + @normal_at_intersection * BIAS,
        :direction => (@direction - @normal_at_intersection * 2 * @direction.dot_product(@normal_at_intersection)).normalize
      )

      reflection_ray.trace(spheres, depth + 1)
    end

    def calculate_refraction(spheres, depth)
      ior = 1.1
        eta = @inside ? ior : (1 / ior)
        cosi = @normal_at_intersection.dot_product(@direction) * -1
        k = 1 - eta * eta * (1 - cosi ** 2)

        refraction_ray = Ray.new(
          :origin => @point_of_intersection - @normal_at_intersection * BIAS,
          :direction => (@direction * eta + @normal_at_intersection * (eta * cosi - Math.sqrt(k))).normalize
        )

        refraction_ray.trace(spheres, depth + 1)
    end

    def mix(a, b, mix)
      b * mix + a * (1 - mix)
    end
end