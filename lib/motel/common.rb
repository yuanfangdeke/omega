# common & useful methods and other.
#
# Things that don't fit elsewhere
#
# Copyright (C) 2010-2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

# include logger dependencies
require 'logger'

module Motel

# generate a random id
def self.gen_uuid
  ["%02x"*4, "%02x"*2, "%02x"*2, "%02x"*2, "%02x"*6].join("-") %
      Array.new(16) {|x| rand(0xff) }
end

# normalize a vector if not normal already, 
# eg divide each component x,y,z by the 
# vector length and return them
def self.normalize(x,y,z)
  return x,y,z if x.nil? || y.nil? || z.nil?

  l = Math.sqrt(x**2 + y**2 + z**2)
  raise ArgumentError if l <= 0

  x /= l
  y /= l
  z /= l
  return x,y,z
end

# determine if a vector is normalized
def self.normalized?(x,y,z)
  return false if x.nil? || y.nil? || z.nil?
  l = Math.sqrt(x**2 + y**2 + z**2)
  l.to_f.round_to(1) == 1  # XXX not quite sure why to_f.round_to(1) is needed
end

# determine if two vectors are orthogonal
def self.orthogonal?(x1,y1,z1, x2,y2,z2)
  return false if x1.nil? || y1.nil? || z1.nil? || x2.nil? || y2.nil? || z2.nil?
  return (x1 * x2 + y1 * y2 + z1 * z2).abs < 0.00001 # TODO close enough?
end

# generate two orthogonal, normalized vectors
def self.random_axis(args = {})
  dimensions  = args[:dimensions]  || 3
  raise ArgumentError if dimensions != 2 && dimensions != 3

  axis = []

  # generate random initial axis
  nx,ny,nz = (rand(2) == 0 ? 1 : -1), (rand(2) == 0 ? 1 : -1), (rand(2) == 0 ? 1 : -1)
  x1,y1,z1 = 0,0,0
  x1,y1,z1 =
     nx * rand(10), ny * rand(10), nz * rand(10) while x1 == 0 || y1 == 0 || z1 == 0
  z1 = 0 if dimensions == 2
  x1,y1,z1 = *Motel::normalize(x1, y1, z1)

  # generate two coordinates of the second,
  # calculate the final coordinate
  nx,ny,nz = (rand(2) == 0 ? 1 : -1), (rand(2) == 0 ? 1 : -1), (rand(2) == 0 ? 1 : -1)
  y2,z2 = 0,0
  y2,z2 = ny * rand(10), nz * rand(10) while y2 == 0 || z2 == 0
  z2 = 0 if dimensions == 2
  x2 = ((y1*y2 + z1*z2) * -1 / x1)
  x2,y2,z2 = *Motel::normalize(x2, y2, z2)

  return [[x1,y1,z1],[x2,y2,z2]]
end

end # module Motel

# provide floating point rounding mechanism
class Float
  def round_to(precision)
     return nil if precision <= 0
     return (self * 10 ** precision).round.to_f / (10 ** precision)
  end
end

# so we don't need to distinguish between an int and float to use round_to
class Fixnum
  def round_to(precision)
    return self
  end
end
