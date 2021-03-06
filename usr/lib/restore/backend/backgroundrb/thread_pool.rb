# Copyright (c) 2006, 2007 Ruffdogs Software, Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

module BackgrounDRb

  class ThreadPool
    attr_reader :pool
    def initialize(size)
      @pool = []
      @size = size
      @mutex = Mutex.new
      @cv = ConditionVariable.new  
    end

    def ex
      @mutex.synchronize { yield }
    end  

    def empty_pool!
      ex { @cv.wait(@mutex) until @pool.empty? }
    end
    
    def dispatch
      puts "dispatching into thread pool" if $DEBUG
      Thread.new do
        # Wait for space in the pool.
        ex {
          until @pool.size <= @size
            puts "Still waiting, #{@pool.size} threads already in @pool" if $DEBUG        
            # Sleep until some other thread calls @cv.signal.
            @cv.wait(@mutex)
          end
        }
        
        @pool << Thread.current
        
        begin
          puts "My turn to yield: " if $DEBUG
          yield
        rescue => e
          puts  "#{ e.message } - (#{ e.class })" << 
            "\n" << (e.backtrace or []).join("\n")
          puts "Exception in thread #{self}: #{e}" if $DEBUG
          #args.first.delete_worker args.last
        ensure
          ex {
            # Remove the thread from the pool.
            @pool.delete(Thread.current)
            #puts "deleting '#{args.last}'" if $DEBUG
            #args.first.delete_worker args.last
            # Signal the next waiting thread that there's a space in the pool.
            @cv.signal            
          }
        end
      end
    end

  end
  
end  
