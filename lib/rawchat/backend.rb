require "yajl"

module Rawchat
  class Backend
    def initialize(options = {})
      @parsers = {}
      @nicknames = {}
      @rev_nicknames = {}
      @channels = {}
      @rev_channels = {}
      @auth = options[:auth_backend] || raise("Must give me a auth_backend!")
    end

    def nickname_of(client)
      @nicknames[client]
    end

    def set_nickname(client, nick)
      @nicknames[client] = nick
      @rev_nicknames[nick] = client
    end

    def join_channel(client, chan)
      @channels[chan] ||= []
      return if @channels[chan].include? client
      @channels[chan] << client
      @rev_channels[client] ||= []
      return if @rev_channels[client].include? chan
      @rev_channels[client] << chan
    end

    def quit_channel(client, chan)
      return unless @channels[chan].include? client
      @channels[chan].delete client if @channels[chan]
      @rev_channels[client].delete chan if @rev_channels[client]
      @channels.delete chan if @channels[chan].empty?
    end

    def in_channel?(client, chan)
      @channels[chan] and @rev_channels[client].include? chan
    end

    def each_client_in_channel(chan, &block)
      @channels[chan].each &block
    end

    def encode(obj, cl)
      Yajl::Encoder.encode(obj, cl)
    end

    def process_action(client, request)
      if respond_to? "do_#{request[:method]}".to_sym
        send "do_#{request[:method]}".to_sym, client, request
      else
        encode({
          type: "error",
          error: "unknown method",
          response_for: request[:request_id]
        }, client)
      end
    end

    def do_quit_channel(client, request)
      quit_channel client, request[:channel]
      encode({
        type: "success",
        response_for: request[:request_id]
      }, client)
    end

    def do_join_channel(client, request)
      join_channel client, request[:channel]
      encode({
        type: "success",
        response_for: request[:request_id]
      }, client)
    end

    def do_auth(client, request)
      if nickname_of(client)
        encode({
          type: "error",
          error: "already has nickname",
          response_for: request[:request_id]
        }, client)
      else
        res = @auth.auth request[:key]
        if res
          set_nickname client, res
          encode({
            type: "success",
            new_nickname: res,
            response_for: request[:request_id]
          }, client)
        else
          encode({
            type: "error",
            error: "auth_fail",
            response_for: request[:request_id]
          }, client)
        end
      end
    end

    def do_send_message(client, request)
      if nickname_of client
        if in_channel? client, request[:to]
          each_client_in_channel request[:to] do |c|
            encode({
              type: "event",
              event: "message",
              channel: request[:to],
              from: nickname_of(client),
              message: request[:message]
            }, c)
          end

          encode({
            type: "success",
            response_for: request[:request_id]
          }, client)
        else
          encode({
            type: "error",
            error: "not in the channel",
            response_for: request[:request_id]
          }, client)
        end
      else
        encode({
          type: "error",
          error: "no nickname",
          response_for: request[:request_id]
        }, client)
      end
    end

    def connected?(c)
      @parsers.has_key? c
    end

    def connected(c)
      @parsers[c] = Yajl::Parser.new symbolize_keys: true
      @parsers[c].on_parse_complete = lambda do |result|
        process_action c, result
      end
    end

    def disconnected(c)
      @parsers.delete c
      n = @nicknames.delete c
      @rev_nicknames.delete n if n
      cs = @rev_channels.delete c
      cs.each { |ch| quit_channel c, ch} if cs
    end

    def disconnect!(c)
      c.close
      disconnected c
    end

    def put_data(c, data)
      return unless @parsers.has_key? c
      @parsers[c] << data
    rescue Yajl::ParseError => e
      encode({
        type: "error",
        error: "parse error",
        disconnect: true,
        error_msg: e.to_s
      }, c)
      disconnect! c
    end
  end
end

if __FILE__ == $0
  require "rawchat/auth"
  a = Rawchat::SampleAuthBackend.new
  b = Rawchat::Backend.new auth_backend: a
  begin
    gem "pry", "~> 0.10"
    require "pry"
    binding.pry
  rescue Gem::LoadError
    require "irb"
    B = b
    IRB.start
  end
end