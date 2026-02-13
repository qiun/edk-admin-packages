class AddSenderAddressesToEditions < ActiveRecord::Migration[8.0]
  def change
    # Order sender (Magazyn EDK)
    add_column :editions, :order_sender_name, :string, null: false, default: "Magazyn EDK - Rafał Wojtkiewicz"
    add_column :editions, :order_sender_street, :string, null: false, default: "ul. Konarskiego 8"
    add_column :editions, :order_sender_city, :string, null: false, default: "Świebodzin"
    add_column :editions, :order_sender_post_code, :string, null: false, default: "66-200"
    add_column :editions, :order_sender_phone, :string, null: false, default: "602736554"
    add_column :editions, :order_sender_email, :string, null: false, default: "pakiety@edk.org.pl"

    # Donation sender (Sklep EDK)
    add_column :editions, :donation_sender_name, :string, null: false, default: "Sklep EDK - Rafał Wojtkiewicz"
    add_column :editions, :donation_sender_street, :string, null: false, default: "ul. Sobieskiego 19"
    add_column :editions, :donation_sender_city, :string, null: false, default: "Świebodzin"
    add_column :editions, :donation_sender_post_code, :string, null: false, default: "66-200"
    add_column :editions, :donation_sender_phone, :string, null: false, default: "602736554"
    add_column :editions, :donation_sender_email, :string, null: false, default: "pakiety@edk.org.pl"
  end
end
