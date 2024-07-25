class Operation < ApplicationRecord
  enum status: {
    pending: 0,
    running: 1,
    success: 2,
    failed: 3,
    killed: 4
  }

  enum kill_status: {
    disabled: 0,
    requested: 1,
    confirmed: 2,
    failed: 3
  }, _prefix: :kill

  after_create do
    OperationRunJob.perform_later(self.id)
  end

  after_save_commit do
    broadcast_replace_to self
  end

  after_destroy_commit do
    broadcast_remove_to self
  end
end
