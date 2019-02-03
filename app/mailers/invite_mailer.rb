class InviteMailer < ApplicationMailer
  default from: 'invites-no-reply@example.com'

  after_action { @invite.update_attributes(sent_at: DateTime.now) }
 
  def existing_user_invite(invite)
    @invite = invite
    @family = @invite.family
    @sender = @invite.sender
    @recipient = @invite.email
    # host = ENV['HOST']
    # @url  = "#{host}/login"
    mail(to: @recipient, subject: "You've been invited by #{@sender.name} to join the #{@family.family_name} family on FamNet!")
  end

  def new_user_invite(invite, url)
    @invite = invite
    @family = @invite.family
    @sender = @invite.sender
    @recipient = @invite.email
    host = ENV['HOST'] # has a weird / before  | '/http://example.com:3000'
    @registration_url = url
    # @url  = "#{host}/login"
    mail(to: @recipient, subject: "You've been invited by #{@sender.name} to join the #{@family.family_name} family on FamNet!")
  end

end
