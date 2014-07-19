require "eventmachine"

require "rawchat/backend"

module Rawchat::Frontend
  module EventMachine
    class EventMachineBase < ::EventMachine::Connection
      alias write send_data
      alias close close_connection_after_writing

      def post_init
        backend.connected self
      end

      def unbind
        puts "unbind"
        backend.disconnected self if backend.connected? self
      end

      def receive_data(data)
        backend.put_data self, data
      end

    end

    def self.make(b)
      Class.new EventMachineBase do
        @@back = b

        def backend; @@back; end
      end
    end
  end
end

if __FILE__ == $0
  EM.run do
    require "pry-remote"
    require "rawchat/backend"
    require "rawchat/auth"
    au = Rawchat::SampleAuthBackend.new
    ba = Rawchat::Backend.new auth_backend: au
    EM.start_server "127.0.0.1", 23333, Rawchat::Frontend::EventMachine.make(ba)

    Thread.new do
      binding.remote_pry
    end
  end
end
