class Numeric
  def clamp min, max
    return min if self <= min
    return max if self >= max
    self
  end
end


class Hash
  def self.deep_sum *args
    args.inject({}) do |result, options|
      result.deep_merge options
    end
  end
end
