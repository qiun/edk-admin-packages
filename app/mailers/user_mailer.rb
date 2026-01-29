# frozen_string_literal: true

# Mailer for user account-related emails (primarily for leaders)
class UserMailer < ApplicationMailer
  default from: ENV.fetch("LEADER_EMAIL_FROM", "pakiety@edk.org.pl")

  # Send welcome email with password setup link
  # @param user [User] the user record
  # @param token [String] raw reset password token
  def welcome_with_password_setup(user, token)
    @user = user
    @password_setup_url = edit_user_password_url(reset_password_token: token)

    mail(
      to: @user.email,
      subject: "Witaj w systemie EDK Packages - Ustaw swoje hasło"
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
