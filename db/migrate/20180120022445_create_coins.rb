class CreateCoins < ActiveRecord::Migration[5.1]
  def change
    create_table :coins do |t|
      t.string :name
      t.string :symbol
      t.float :fee
      t.integer :confirmations
      t.references :market, foreign_key: true
      t.string :address

      t.timestamps
    end
  end
end
