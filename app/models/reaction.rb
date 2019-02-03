class Reaction < ApplicationRecord
  belongs_to :interaction, polymorphic: true
  belongs_to :member
  include Notifiable
  before_commit :delete_old_reaction_on_interaction

  # These are the types of constants that are allowed to have interactions.
  enum :emotive => {heart: 0, like: 1, dislike: 2, haha: 3, wow: 4, sad: 5, angry: 6}

  # This method removes the lowest interaction id of the two based on
  # reactions of interaction where member_id is the passed member_id.
  # This should result in no more than two records being returned which only
  # happens during create to delete the old interaction.
  # This method eliminates the need to manage reaction updates on the front-end.
  def delete_old_reaction_on_interaction
    reactions_on_interaction = self.interaction.reactions.where(member_id: member_id)
    unless reactions_on_interaction.count <= 1
      reactions_on_interaction.order(id: :asc).first.delete
    end
  end
end
