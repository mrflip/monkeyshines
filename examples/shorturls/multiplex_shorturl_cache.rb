class Monkeyshines::ScrapeStore::MultiplexShorturlCache < Monkeyshines::ScrapeStore::ReadThruStore
  attr_accessor :dests, :store_uris

  # Store into tokyo tyrant
  # TYRANT_PORTS = { 'tinyurl' => ":10001", 'bitly' => ":10002", 'other' => ":10003" }

  def initialize store_uris, options={}
    self.dests = { }
    store_uris.each do |handle, uri|
      dests[handle] = Monkeyshines::ScrapeStore::ReadThruStore.new uri
    end
  end

  def set key, *args, &block
    case
    when (key =~ %r{^http://tinyurl.com/(.*)}) then dests['tinyurl'].set($1,  *args, &block)
    when (key =~ %r{^http://bit.ly/(.*)})      then dests['bitly'  ].set($1,  *args, &block)
    else                                            dests['other'  ].set(key, *args, &block)
    end
  end

  def size
    dests.inject(0){|sum,hand_db| sz += hand_db[1].size }
  end
  def close
    dests.each{|hdl,db| db.close }
  end
end




