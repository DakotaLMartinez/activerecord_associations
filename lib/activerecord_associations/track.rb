class Track < ActiveRecord::Base
  self.table_name = "Track"
  has_many :playlist_tracks, foreign_key: "TrackId"
  has_many :playlists, through: :playlist_tracks
end