module Admin
  module ShipmentsHelper
    # Parse locker information from locker_name when individual fields are empty
    # Format: "CODE - Address, POSTAL_CODE City"
    # Example: "KRA39M - Borkowska 1, 30-438 Kraków"
    def parse_locker_info(source)
      # If individual fields are populated, use them
      if source.locker_address.present?
        return {
          address: source.locker_address,
          city: source.locker_city,
          postal_code: source.locker_post_code
        }
      end

      # Otherwise, parse from locker_name
      return { address: "", city: "", postal_code: "" } if source.locker_name.blank?

      # Remove code prefix if present (e.g., "KRA39M - ")
      name_without_code = source.locker_name.sub(/^#{Regexp.escape(source.locker_code)}\\s*-\\s*/, "")

      # Split by comma to separate address from "postal_code city"
      parts = name_without_code.split(",").map(&:strip)
      return { address: "", city: "", postal_code: "" } if parts.empty?

      address = parts[0] || ""

      # Parse "30-438 Kraków" into postal_code and city
      postal_and_city = parts[1]&.strip || ""
      if postal_and_city =~ /^(\\d{2}-\\d{3})\\s+(.+)$/
        postal_code = $1
        city = $2
      else
        postal_code = ""
        city = postal_and_city
      end

      { address: address, city: city, postal_code: postal_code }
    end
  end
end
