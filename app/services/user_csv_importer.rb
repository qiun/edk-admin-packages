require "csv"

class UserCsvImporter
  def initialize(file, created_by:)
    @file = file
    @created_by = created_by
  end

  def call
    result = { created: 0, skipped: 0, errors: [] }

    CSV.foreach(@file.path, headers: true, col_sep: detect_separator) do |row|
      import_row(row, result)
    end

    result
  end

  private

  def import_row(row, result)
    email = row["email"]&.strip&.downcase
    return result[:errors] << "Brak email w wierszu" if email.blank?

    if User.exists?(email: email)
      result[:skipped] += 1
      return
    end

    # Generate random password (user won't know it)
    # Use User.generate_secure_password to guarantee all complexity requirements
    random_password = User.generate_secure_password

    user = User.new(
      email: email,
      first_name: row["first_name"]&.strip || row["imię"]&.strip,
      last_name: row["last_name"]&.strip || row["nazwisko"]&.strip,
      phone: row["phone"]&.strip || row["telefon"]&.strip,
      role: :leader,
      created_by: @created_by,
      password: random_password,
      password_confirmation: random_password
    )

    if user.save
      result[:created] += 1

      # Generate password reset token
      raw_token, enc_token = Devise.token_generator.generate(User, :reset_password_token)
      user.reset_password_token = enc_token
      user.reset_password_sent_at = Time.current
      user.save(validate: false)

      # Send welcome email with password setup link (synchronously for simplicity)
      begin
        UserMailer.welcome_with_password_setup(user, raw_token).deliver_now
      rescue Net::SMTPAuthenticationError, Net::SMTPServerBusy, Net::SMTPSyntaxError, Net::SMTPFatalError, Net::SMTPUnknownError, Net::ReadTimeout, Net::OpenTimeout, Errno::ECONNREFUSED, SocketError => e
        Rails.logger.error "Failed to send welcome email to #{user.email}: #{e.message}"
        # Continue with import even if email fails
      end
    else
      result[:errors] << "#{email}: #{user.errors.full_messages.join(', ')}"
    end
  end

  def detect_separator
    first_line = File.open(@file.path, &:readline)
    first_line.include?(";") ? ";" : ","
  rescue StandardError
    ","
  end
end
