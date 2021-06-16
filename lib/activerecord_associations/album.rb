class Album < ActiveRecord::Base
  self.table_name = "Album"
  belongs_to :artist, foreign_key: "ArtistId"
end