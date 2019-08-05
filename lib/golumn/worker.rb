module Golumn
  class Worker < Thread
    WORKER_EXIT_SIGNAL = :__golumn_worker_thread_exit__
    DEFAULT_EXCEPTION_HANDLER = ->(e) { warn e }

    def initialize(batch_size: 10, exception_handler: DEFAULT_EXCEPTION_HANDLER)
      @queue = Queue.new
      @exiting = false
      @batch_size = batch_size
      @exception_handler = exception_handler

      super do
        loop do
          is_done = false
          jobs = []
          while (job = @queue.pop)
            if job == WORKER_EXIT_SIGNAL
              is_done = true
              break
            end

            jobs << job
            break if @queue.size.zero?
            break if jobs.count >= @batch_size
          end

          begin
            yield(jobs) if jobs.any?
          rescue StandardError => e
            @exception_handler.call(e)
          end

          break if is_done
        end
      end

      at_exit do
        exit!
        join
      end
    end

    def perform(job)
      Array(job).each { |j| @queue.push(j) }
    end

    def exit!
      @exiting = true
      @queue.push(WORKER_EXIT_SIGNAL)
    end
  end
end
