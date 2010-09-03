module Sourcify
  module Proc
    module Scanner #:nodoc:all
      module Extensions

        class Escape < Exception; end

        def process(data)
          begin
            reset_collectibles
            @results, @lineno = [], 1
            @data = data.unpack("c*")
            execute!
          rescue Escape
            @results
          end
        end

        def push(ts, te)
          @tokens << @data[ts .. te.pred].pack('c*')
        end

        def increment_line
          @lineno += 1
          raise Escape if @lineno > 1 && !@results.empty?
        end

        def increment(type, key)
          send(:"increment_#{key}_counter", type)
        end

        def decrement(type, key)
          send(:"decrement_#{key}_counter")
        end

        def increment_do_end_counter(type)
          return if @brace_counter.started?
          case type
          when :do_block_nstart1 then @do_end_counter.increment
          when :do_block_nstart2 then @do_end_counter.increment(0..1)
          when :do_block_start
            unless @do_end_counter.started?
              @lineno = 1 # Fixing JRuby's lineno bug (see http://jira.codehaus.org/browse/JRUBY-5014)
              last = @tokens[-1]
              @tokens.clear
              @tokens << last
            end
            @do_end_counter.increment
          end
        end

        def decrement_do_end_counter
          return unless @do_end_counter.started?
          @do_end_counter.decrement
          construct_result_code if @do_end_counter.balanced?
        end

        def construct_result_code
          begin
            code = 'proc ' + @tokens.join
            eval(code) # TODO: is there a better way to check for SyntaxError ?
            @results << code
            raise Escape unless @lineno == 1
            reset_collectibles
          rescue SyntaxError
          end
        end

        def reset_collectibles
          @tokens = []
          @do_end_counter = Counter.new
          @brace_counter = Counter.new
        end

        class Counter

          attr_reader :counts

          def initialize
            @counts = [0,0]
          end

          def started?
            @counts.any?(&:nonzero?)
          end

          def balanced?
            @counts.any?(&:zero?)
          end

          def decrement
            (0..1).each{|i| @counts[i] -= 1 unless @counts[i].zero? }
          end

          def increment(val = 1)
            if val.is_a?(Range)
              @counts[0] += val.first
              @counts[1] += val.last
            else
              (0..1).each{|i| @counts[i] += 1 }
            end
          end

        end

      end
    end
  end
end
