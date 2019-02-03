module Interaction
  extend ActiveSupport::Concern

  included do
    has_many :reactions, :as => :interaction
  end
end