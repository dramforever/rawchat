module Rawchat
  class AuthBackend
    def initialize
      raise "Do not use AuthBackend directly!"
    end

    ##
    # Pass in a key, return the nickname, or nil if auth failed
    def auth(key)
      raise "Do not use AuthBackend directly"
    end
  end

  class SampleAuthBackend
    def initialize; end

    def auth(key)
      case key
        when "admin" then "admin"
        when "user" then "user"
        else nil
      end
    end
  end
end