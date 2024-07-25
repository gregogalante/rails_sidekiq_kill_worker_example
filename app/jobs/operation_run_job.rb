class OperationRunJob < ApplicationJob
  def perform(operation_id)
    operation = Operation.find_by_id(operation_id)
    return unless operation&.pending?

    wait_thr = nil
    wait_thr_mutex = Mutex.new

    thread_runner = Thread.new do
      operation.update!(status: :running, started_at: Time.now)

      begin
        operation_script_path = Rails.root.join('vendor', 'operation.py')
        stdin, stdout, stderr, thread_wait_thr = Open3.popen3("python3 #{operation_script_path}")

        wait_thr_mutex.synchronize { wait_thr = thread_wait_thr }

        # Create a separate thread to read from stdout (if needed)
        stdout_thread = Thread.new { stdout.read }

        # Wait for the command to finish or be interrupted
        thread_wait_thr.join
      rescue StandardError => e
        Rails.logger.error(e)
        Rails.logger.error(e.backtrace.join("\n"))
      ensure
        # Ensure all streams are closed
        [stdin, stdout, stderr].each { |io| io.close rescue nil }
        stdout_thread.kill if stdout_thread # Kill stdout reading thread if it exists
      end

      operation.update!(status: :success, ended_at: Time.now)
    end

    thread_checker = Thread.new do
      while thread_runner.alive?
        sleep 5
        operation.reload
        next unless operation.kill_status == 'requested'

        wait_thr_mutex.synchronize do
          if wait_thr && wait_thr.pid
            Process.kill("INT", wait_thr.pid)
            operation.update!(
              kill_status: :confirmed,
              status: :killed,
              ended_at: Time.now
            )
          else
            operation.update!(kill_status: :failed)
          end
        end
        break
      end
    end

    thread_runner.join
    thread_checker.join
  rescue StandardError => e
    Rails.logger.error(e)
    operation&.update!(status: :failed, ended_at: Time.now)
  end

  # def OLD_perform(operation_id)
  #   operation = Operation.find_by_id(operation_id)
  #   return unless operation&.pending?

  #   thread_runner = Thread.new do
  #     operation.update!(status: :running, started_at: Time.now)

  #     counter = 0
  #     while counter < 60
  #       counter += 1
  #       operation.update!(pinged_at: Time.now)
  #       sleep(1)
  #     end

  #     # operation_script_path = Rails.root.join('vendor', 'operation.py')
  #     # `python3 #{operation_script_path}`

  #     operation.update!(status: :success, ended_at: Time.now)
  #   end

  #   thread_checker = Thread.new do
  #     while thread_runner.alive?
  #       sleep 5
  #       operation.reload

  #       if operation.kill_status == 'requested'
  #         begin
  #           thread_runner.kill
  #           operation.update!(
  #             kill_status: :confirmed,
  #             status: :killed,
  #             ended_at: Time.now
  #           )
  #         rescue StandardError => e
  #           Rails.logger.error(e)
  #           operation.update!(kill_status: :failed)
  #         end
  #       end
  #     end
  #   end

  #   thread_runner.join
  #   thread_checker.join
  # rescue StandardError => e
  #   Rails.logger.error(e)
  #   operation&.update!(status: :failed, ended_at: Time.now)
  # end
end
