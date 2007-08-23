class ConcurrentlyAccessed
  class Error < Exception; end
  
  def invoke *args
    @invoked_count += 1
    @invoked_args = args
  end

  def invoke_raises *args
    @invoked_count += 1
    @invoked_args = args
    raise Error.new(args.inspect)
  end

  def initialize
    @invoked_count = 0
    @invoked_args = nil
  end      

  attr_reader :invoked_count, :invoked_args
end
