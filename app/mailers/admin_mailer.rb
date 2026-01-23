class AdminMailer < ApplicationMailer
  default from: "pakiety@edk.org.pl"

  def low_stock_alert(edition:, available:, admin_emails:)
    @edition = edition
    @available = available
    
    mail(
      to: admin_emails,
      subject: "[PAKIETY EDK] ⚠️ Niski stan magazynowy - #{edition.name}"
    )
  end

  def out_of_stock_alert(edition:, admin_emails:)
    @edition = edition
    
    mail(
      to: admin_emails,
      subject: "[PAKIETY EDK] 🚨 BRAK PAKIETÓW - #{edition.name}"
    )
  end
end
