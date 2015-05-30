ActiveRecord::Schema.define do
  self.verbose = false

  create_table :companies, force: true do |t|
    t.string :name
    t.string :description
  end

  create_table :users, force: true do |t|
    t.references :company
    t.string :name
    t.string :email
  end

  create_table :categories, force: true do |t|
    t.string :name
    t.string :description
  end

  create_table :posts, force: true do |t|
    t.references :user
    t.references :category
    t.string :title
    t.string :text
  end

  create_table :comments, force: true do |t|
    t.references :user
    t.references :post
    t.string :title
    t.string :text
    t.timestamps null: false
  end

  add_foreign_key :users, :company
  add_foreign_key :posts, :user
  add_foreign_key :posts, :category
  add_foreign_key :comments, :user
  add_foreign_key :comments, :post
end
