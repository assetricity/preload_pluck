class Company < ActiveRecord::Base
  has_many :users
end

class User < ActiveRecord::Base
  belongs_to :company
  has_many :posts
  has_many :comments
end

class Category < ActiveRecord::Base
  has_many :posts
end

class Post < ActiveRecord::Base
  belongs_to :user
  belongs_to :category
  has_many :comments
end

class Comment < ActiveRecord::Base
  belongs_to :user
  belongs_to :post
end
