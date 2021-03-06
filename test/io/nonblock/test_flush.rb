require 'test/unit'
require 'timeout'
begin
  require 'io/nonblock'
rescue LoadError
end

class TestIONonblock < Test::Unit::TestCase
  def test_flush
    IO.pipe {|r, w|
      return if flush_test(r, w)
    }
    require 'socket';
    Socket.pair(:INET, :STREAM) {|s1, s2|
      return if flush_test(s1, s2)
    }
    skip "nonblocking IO did not work"
  end

  def flush_test(r, w)
    begin
      w.nonblock = true
    rescue Errno::EBADF
      return false
    end
    w.sync = false
    w << "b"
    w.flush
    w << "a" * 4096
    result = ""
    Timeout.timeout(10) {
      t0 = Thread.new {
        Thread.pass
        w.close
      }
      t = Thread.new {
        while (Thread.pass; s = r.read(4096))
          result << s
        end
      }
      begin
        w.flush # assert_raise(IOError, "[ruby-dev:24985]") {w.flush}
      rescue Errno::EBADF, IOError
        # ignore [ruby-dev:35638]
      end
      assert_nothing_raised {t.join}
      t0.join
    }
    assert_equal(4097, result.size)
    true
  end
end if IO.method_defined?(:nonblock)
