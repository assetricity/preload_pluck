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
end

