class User < ActiveRecord::Base
  has_many :posts, foreign_key: "author_id"
end 

# class Post < ActiveRecord::Base
#   belongs_to :author, class_name: "User"
# end