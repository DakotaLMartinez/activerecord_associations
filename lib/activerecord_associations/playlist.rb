class Playlist < ActiveRecord::Base
  self.table_name = name
  has_many :playlist_tracks, foreign_key: "PlaylistId"
  has_many :tracks, through: :playlist_tracks
end