# Add Many to Many relationship between Post and Tag models.
class Post < ActiveRecord::Base
  has_many :post_tags
  has_many :tags, through: :post_tags
end

class PostTag < ActiveRecord::Base
  belongs_to :post
  belongs_to :tag
end 

class Tag < ActiveRecord::Base
  has_many :post_tags
  has_many :posts, through: :post_tags
end