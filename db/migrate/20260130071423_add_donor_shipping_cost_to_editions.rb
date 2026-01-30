class AddDonorShippingCostToEditions < ActiveRecord::Migration[8.1]
  def up
    # Dodaj nowe pole dla kosztu wysyłki
    add_column :editions, :donor_shipping_cost, :decimal, precision: 8, scale: 2, default: 20.0, null: false

    # Zmień nazwę donor_price na donor_brick_price dla jasności
    rename_column :editions, :donor_price, :donor_brick_price

    # Ustaw domyślną wartość dla istniejących edycji
    # Zakładamy: stara cena 50 zł = 30 zł cegiełka + 20 zł wysyłka
    Edition.reset_column_information
    Edition.find_each do |edition|
      # Jeśli poprzednia cena była 50, ustaw 30 za cegiełkę + 20 za wysyłkę
      if edition.donor_brick_price == 50
        edition.update_columns(donor_brick_price: 30.0, donor_shipping_cost: 20.0)
      else
        # Dla innych wartości, odejmij 20 od ceny jako przybliżenie
        new_brick_price = [edition.donor_brick_price - 20, 10].max
        edition.update_columns(donor_brick_price: new_brick_price, donor_shipping_cost: 20.0)
      end
    end
  end

  def down
    # Przy rollback, połącz wartości z powrotem
    Edition.reset_column_information
    Edition.find_each do |edition|
      combined_price = edition.donor_brick_price + edition.donor_shipping_cost
      edition.update_columns(donor_brick_price: combined_price)
    end

    rename_column :editions, :donor_brick_price, :donor_price
    remove_column :editions, :donor_shipping_cost
  end
end
