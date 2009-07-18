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

  def set key, &block
    case
    when (key =~ %r{^http://tinyurl.com/(.*)}) then dests['tinyurl'].set($1,  block)
    when (key =~ %r{^http://bit.ly/(.*)})      then dests['bitly'  ].set($1,  block)
    else                                            dests['other'  ].set(key, block)
    end
  end

end




