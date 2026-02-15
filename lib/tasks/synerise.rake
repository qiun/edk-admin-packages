# frozen_string_literal: true

namespace :synerise do
  desc "Migrate existing paid donations to Synerise CRM"
  task migrate_donations: :environment do
    client = Synerise::Client.new

    unless client.enabled?
      puts "Synerise is disabled. Set SYNERISE_ENABLED=true to proceed."
      exit 1
    end

    donations = Donation.paid.includes(:edition).order(:created_at)
    total = donations.count
    puts "Found #{total} paid donations to migrate."

    success = 0
    errors = 0

    donations.find_each do |donation|
      print "Processing donation ##{donation.id} (#{donation.email})... "

      begin
        Synerise::SendDonationEvent.new(donation).call
        success += 1
        puts "OK"
      rescue StandardError => e
        errors += 1
        puts "ERROR: #{e.message}"
      end

      # Throttle requests to avoid rate limiting
      sleep 0.5
    end

    puts "\nMigration complete: #{success} succeeded, #{errors} failed out of #{total} total."
  end
end
