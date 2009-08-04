module Monkeyshines
  module RequestStream
    extend FactoryModule
    autoload :Base,                  'monkeyshines/request_stream/base'
    autoload :BeanstalkQueue,        'monkeyshines/request_stream/beanstalk_queue'
    autoload :FlatFileRequestStream, 'monkeyshines/request_stream/flat_file_request_stream'
  end
end
