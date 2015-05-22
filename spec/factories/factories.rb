FactoryGirl.define do
  factory :company do
    sequence(:name) {|n| "Company #{n}"}
  end

  factory :user do
    sequence(:name) {|n| "User #{n}"}
    company
  end

  factory :category do
    sequence(:name) {|n| "Category #{n}"}
  end

  factory :post do
    sequence(:text) {|n| "Post #{n}"}
    user
    category
  end

  factory :comment do
    sequence(:text) {|n| "Comment #{n}"}
    user
    post
  end
end
