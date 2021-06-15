class Artist < ActiveRecord::Base
  self.table_name = "Artist"
  has_many :albums, foreign_key: "ArtistId" # use ArtistId instead of artist_id when making queries to get related albums.
end