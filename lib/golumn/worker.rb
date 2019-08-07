module Golumn
  class Worker
    WORKER_EXIT_SIGNAL = :__golumn_worker_thread_exit__
    DEFAULT_EXCEPTION_HANDLER = ->(e) { warn e }

    STATE = {
      running: 0,
      stopping: 1,
      stopped: 2
    }.freeze

    def initialize(batch_size:, exception_handler: DEFAULT_EXCEPTION_HANDLER)
      @mutex = Mutex.new
      @queue = Queue.new
      @batch_size = batch_size
      @exception_handler = exception_handler
      @state = STATE[:open]

      @thread = Thread.new do
        worker_exit_received = false

        loop do
          break if state == STATE[:stopped]
          break if worker_exit_received

          jobs = []
          while (job = @queue.pop)
            if job == WORKER_EXIT_SIGNAL
              worker_exit_received = true
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
        end
      end

      at_exit do
        stop_and_wait
      end
    end

    def state
      @mutex.synchronize { @state.dup }
    end

    def perform(job)
      return unless state == STATE[:open]

      Array(job).each { |j| @queue.push(j) }
    end

    def stop_and_wait
      @mutex.synchronize { @state = STATE[:stopping] }
      @queue.push(WORKER_EXIT_SIGNAL)
      @thread.join
      @mutex.synchronize { @state = STATE[:stopped] }
    end
  end
end
