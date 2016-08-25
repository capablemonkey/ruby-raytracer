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