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

    return Vec3.new(2, 2, 2) if sphere.nil?

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
        cosi = nhit.dot_product(@direction) * -1 # TODO: possible order of ops issue with -nhit
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
      # this is a diffuse object
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

          surface_color += sphere.surface_color * transmission * [0, nhit.dot_product(light_direction)].max * s.emission_color
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