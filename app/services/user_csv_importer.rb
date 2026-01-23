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

    user = User.new(
      email: email,
      first_name: row["first_name"]&.strip || row["imię"]&.strip,
      last_name: row["last_name"]&.strip || row["nazwisko"]&.strip,
      phone: row["phone"]&.strip || row["telefon"]&.strip,
      role: :leader,
      created_by: @created_by,
      password: SecureRandom.hex(8)
    )

    if user.save
      result[:created] += 1
      # TODO: UserMailer.welcome(user).deliver_later
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
