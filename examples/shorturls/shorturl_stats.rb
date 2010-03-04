class ShorturlStats < Struct.new(
    :success_tot,
    :failure_tot,
    :success_last,
    :fail_last
    )
    
  def code_sort code
    case code.to_i
    when 404
      self.failure_tot += 1
      self.fail_last += 1
    when 301
      self.success_tot += 1
      self.success_last += 1
    else 
      warn 'Code not included in stats.'
    end
  end
  
  def rates_inst
    s_rate = (self.success_last.to_f)/(self.success_last.to_f + self.fail_last.to_f)
    f_rate = (self.fail_last.to_f)/(self.success_last.to_f + self.fail_last.to_f)
    self.success_last = 0
    self.fail_last = 0
    [s_rate,f_rate]
  end
  
  def rates_tot
    st_rate = (self.success_tot.to_f)/(self.success_tot.to_f + self.failure_tot.to_f)
    ft_rate = (self.failure_tot.to_f)/(self.success_tot.to_f + self.failure_tot.to_f)
    [st_rate,ft_rate]
  end
    
end
