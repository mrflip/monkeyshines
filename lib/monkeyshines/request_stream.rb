module Monkeyshines
  module RequestStream
    extend FactoryModule
    autoload :Base,                   'monkeyshines/request_stream/base'
    autoload :KlassRequestStream,     'monkeyshines/request_stream/klass_request_stream'
    autoload :KlassHashRequestStream, 'monkeyshines/request_stream/klass_request_stream'
    autoload :SimpleRequestStream,    'monkeyshines/request_stream/simple_request_stream'
    autoload :BeanstalkQueue,         'monkeyshines/request_stream/beanstalk_queue'
    autoload :EdamameQueue,           'monkeyshines/request_stream/edamame_queue'
  end
end
