FactoryGirl.define do
  factory :company do
    sequence(:name) {|n| "Company #{n}"}
    sequence(:description) {|n| "Company Description #{n}"}
  end

  factory :user do
    sequence(:name) {|n| "User #{n}"}
    sequence(:email) {|n| "user#{n}@example.com"}
    company
  end

  factory :category do
    sequence(:name) {|n| "Category #{n}"}
    sequence(:description) {|n| "Category Description #{n}"}
  end

  factory :post do
    sequence(:title) {|n| "Post Title #{n}"}
    sequence(:text) {|n| "Post #{n}"}
    user
    category
  end

  factory :comment do
    sequence(:title) {|n| "Comment Title #{n}"}
    sequence(:text) {|n| "Comment #{n}"}
    user
    post
  end
end
