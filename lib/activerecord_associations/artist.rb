class Artist < ActiveRecord::Base
  self.table_name = "Artist"
  has_many :albums, foreign_key: "ArtistId"
end