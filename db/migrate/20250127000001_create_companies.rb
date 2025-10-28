class CreateCompanies < ActiveRecord::Migration[7.0]
  def change
    create_table :companies do |t|
      t.string :coc_number, null: false
      t.string :company_name, null: false
      t.string :city, null: false

      t.timestamps
    end

    # Add unique index for coc_number
    add_index :companies, :coc_number, unique: true
    
    # Add indexes for ILIKE queries on company_name and city
    add_index :companies, :company_name
    add_index :companies, :city
    
    # Add composite index for combined searches
    add_index :companies, [:company_name, :city]
  end
end
