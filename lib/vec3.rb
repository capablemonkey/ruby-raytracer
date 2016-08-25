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