class Playlist < ActiveRecord::Base
  self.table_name = "Playlist"
  has_many :playlist_tracks, foreign_key: "PlaylistId"
  has_many :tracks, through: :playlist_tracks
end