module Sourcify
  module Proc
    module Scanner #:nodoc:all
      class Comment

        def <<(content)
          (@contents ||= []) << content
        end

        def to_s
          @contents.join
        end

        def closed?(sealer)
          sealer == "\n"
        end

      end
    end
  end
end
