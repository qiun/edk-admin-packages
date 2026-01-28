class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("LEADER_EMAIL_FROM", "pakiety@edk.org.pl")
  layout "mailer"
end
