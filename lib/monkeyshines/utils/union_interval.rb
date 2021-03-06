#
# A numeric interval
#
# --
# could be done with a Range but proved annoying in practice
# what with Range's immutability, etc.
# ++
#
class UnionInterval
  attr_accessor :min, :max
  # initialize with set min or max values.
  # To create an interval with no lower bound call:
  #   UnionInterval.new(nil, 69)
  # Pass nil (or omit) +max+ for no upper bound:
  #   UnionInterval.new(5, nil)
  def initialize min=nil, max=nil
    self.min = min
    self.max = max
  end
  # Expand the interval to include all the vals
  def << vals
    self.min = [min, vals.to_a].flatten.compact.min
    self.max = [max, vals.to_a].flatten.compact.max
  end
  def + min_max
    sum_min = [min, min_max.to_a].flatten.compact.min
    sum_max = [max, min_max.to_a].flatten.compact.max
    UnionInterval.new sum_min, sum_max
  end
  # returns span as an array:
  #   [min, max]
  def to_a
    [min, max]
  end
  # true if the extent is defined but empty (lower bound exceeds upper bound)
  def empty?
    min && max && (min > max)
  end
  def include? val
    val && (!min || (val >= min)) && (!max || (val <= max))
  end
  def size
    return 0 unless max && min
    max - min
  end
  # string conversion:
  #   #<span:7..956734>
  def to_s
    "#<span:#{min}..#{max}>"
  end
  def inspect() to_s end
end
