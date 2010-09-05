module Sourcify
  module Proc
    module Scanner #:nodoc:all
      class Heredoc < Struct.new(:index, :tag, :indent)

        def contents
          @contents ||= []
        end

        def ending?(next_token)
          return false if contents[-1] !~ /^\w+$/
          return false if "#{contents[-1]}#{next_token}" != "#{tag}\n"
          return true if contents[-2] == "\n"
          indent && contents[-3 .. -2].map(&:squeeze) == ["\n", " "]
        end

      end
    end
  end
end
