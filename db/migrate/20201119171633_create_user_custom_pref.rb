class CreateUserCustomPref < ActiveRecord::Migration[5.2]
  def change

    create_table :user_custom_prefs do |t|
      t.belongs_to :user
      t.string :ctype
      t.string :value
    end
    
  end
end
