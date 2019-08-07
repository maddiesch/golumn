module Golumn
  class Worker
    WORKER_EXIT_SIGNAL = :__golumn_worker_thread_exit__
    DEFAULT_EXCEPTION_HANDLER = ->(e) { warn e }

    STATE = {
      ready: 0,
      running: 1,
      stopping: 2,
      stopped: 3
    }.freeze

    def initialize(batch_size:, exception_handler: DEFAULT_EXCEPTION_HANDLER, &handler)
      @mutex = Mutex.new
      @queue = Queue.new
      @batch_size = batch_size
      @exception_handler = exception_handler
      @state = STATE[:ready]
      @handler = handler

      at_exit do
        stop_and_wait
      end
    end

    def state
      @mutex.synchronize { @state }
    end

    def perform(job)
      return unless state <= STATE[:running]

      create_new_thread if needs_new_thread?

      Array(job).each { |j| @queue.push(j) }
    end

    def stop_and_wait
      @mutex.synchronize { @state = STATE[:stopping] }
      @queue.push(WORKER_EXIT_SIGNAL)
      @mutex.synchronize do
        @thread.join
        @state = STATE[:stopped]
      end
    end

    private

    def needs_new_thread?
      @mutex.synchronize do
        if @thread.nil?
          true
        elsif @thread.status == false || @thread.status.nil?
          true
        else
          false
        end
      end
    end

    def create_new_thread
      @mutex.synchronize { @state = STATE[:running] if @state < STATE[:running] }

      thread = Thread.new do
        worker_exit_received = false

        loop do
          break if @state == STATE[:stopped]
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
            @handler.call(jobs) if jobs.any?
          rescue StandardError => e
            @exception_handler.call(e)
          end
        end
      end

      @mutex.synchronize { @thread = thread }
    end
  end
end
