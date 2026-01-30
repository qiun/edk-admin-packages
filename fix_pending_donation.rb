#!/usr/bin/env ruby
# Script to manually mark pending donation as paid
# Run with: kubectl exec -it deployment/edk-admin-packages -- bin/rails runner fix_pending_donation.rb

# Find the most recent pending donation from today
donation = Donation.where(payment_status: :pending)
                   .where("created_at > ?", Time.current.beginning_of_day)
                   .order(created_at: :desc)
                   .first

if donation
  puts "Found donation ##{donation.id}:"
  puts "  Name: #{donation.first_name} #{donation.last_name}"
  puts "  Email: #{donation.email}"
  puts "  Amount: #{donation.amount} zł"
  puts "  Quantity: #{donation.quantity}"
  puts "  Current status: #{donation.payment_status}"
  puts "  Payment ID: #{donation.payment_id}"
  puts ""

  # Update to paid
  donation.update!(payment_status: :paid)
  puts "✓ Updated donation ##{donation.id} to 'paid'"

  # Send confirmation email
  begin
    DonationMailer.confirmation(donation).deliver_now
    puts "✓ Sent confirmation email"
  rescue => e
    puts "✗ Failed to send email: #{e.message}"
  end

  # Create shipment if gift requested
  if donation.want_gift? && donation.locker_code.present?
    begin
      shipment = Shipment.create!(
        donation: donation,
        status: "pending"
      )
      puts "✓ Created shipment ##{shipment.id}"

      # Queue aPaczka job
      Apaczka::CreateShipmentJob.perform_later(shipment)
      puts "✓ Queued aPaczka shipment creation job"
    rescue => e
      puts "✗ Failed to create shipment: #{e.message}"
    end
  else
    puts "- No gift requested, skipping shipment"
  end

  puts ""
  puts "Done! Donation ##{donation.id} is now marked as paid."
else
  puts "No pending donations found from today."
  puts "Listing all recent donations:"
  Donation.order(created_at: :desc).limit(5).each do |d|
    puts "  ##{d.id} - #{d.first_name} #{d.last_name} - #{d.payment_status} - #{d.created_at}"
  end
end
