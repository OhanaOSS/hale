class Notification < ApplicationRecord

  belongs_to :notifiable, polymorphic: true
  belongs_to :member

end
