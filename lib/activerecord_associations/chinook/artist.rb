class Artist < ActiveRecord::Base
  has_many :albums, foreign_key: "artist_id", primary_key: "google_user_id"
end