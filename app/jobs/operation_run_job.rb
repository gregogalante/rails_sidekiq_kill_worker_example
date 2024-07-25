class OperationRunJob < ApplicationJob
  def perform(operation_id)
    operation = Operation.find_by_id(operation_id)
    return unless operation&.pending?



    thread_runner = Thread.new do
      operation.update!(status: :running, started_at: Time.now)

      counter = 0
      while counter < 60
        counter += 1
        operation.update!(pinged_at: Time.now)
        sleep(1)
      end

      # operation_script_path = Rails.root.join('vendor', 'operation.py')
      # `python3 #{operation_script_path}`

      operation.update!(status: :success, ended_at: Time.now)
    end

    thread_checker = Thread.new do
      while thread_runner.alive?
        sleep 5
        operation.reload

        if operation.kill_status == 'requested'
          begin
            thread_runner.kill
            operation.update!(
              kill_status: :confirmed,
              status: :killed,
              ended_at: Time.now
            )
          rescue StandardError => e
            Rails.logger.error(e)
            operation.update!(kill_status: :failed)
          end
        end
      end
    end

    thread_runner.join
    thread_checker.join
  rescue StandardError => e
    Rails.logger.error(e)
    operation&.update!(status: :failed, ended_at: Time.now)
  end
end
