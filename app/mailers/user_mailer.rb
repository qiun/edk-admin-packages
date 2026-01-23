# frozen_string_literal: true

# Mailer for user account-related emails (primarily for leaders)
class UserMailer < ApplicationMailer
  default from: ENV.fetch("LEADER_EMAIL_FROM", "pakiety@edk.org.pl")

  # Send welcome email when leader account is created
  # @param user [User] the user record
  # @param password [String] temporary password (optional)
  def welcome(user, password = nil)
    @user = user
    @password = password
    @login_url = new_user_session_url

    mail(
      to: @user.email,
      subject: "Witaj w systemie EDK Packages - #{user.full_name}"
    )
  end

  # Send password reset instructions
  # @param user [User] the user record
  # @param reset_url [String] password reset URL
  def password_reset(user, reset_url)
    @user = user
    @reset_url = reset_url

    mail(
      to: @user.email,
      subject: "Instrukcje resetowania hasła - EDK Packages"
    )
  end
end
