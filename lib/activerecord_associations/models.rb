class Artist < ActiveRecord::Base
  self.table_name = "Artist"
  has_many :albums, foreign_key: "ArtistId"
end

class Album < ActiveRecord::Base
  self.table_name = "Album"
  belongs_to :artist, foreign_key: "ArtistId"
end

class Playlist < ActiveRecord::Base
  self.table_name = "Playlist"
  has_many :playlist_tracks, foreign_key: "PlaylistId"
  has_many :tracks, through: :playlist_tracks
end

class PlaylistTrack < ActiveRecord::Base
  self.table_name = "PlaylistTrack"
  belongs_to :playlist, foreign_key: "PlaylistId"
  belongs_to :track, foreign_key: "TrackId"
end

class Track < ActiveRecord::Base
  self.table_name = "Track"
  has_many :playlist_tracks, foreign_key: "TrackId"
  has_many :playlists, through: :playlist_tracks
end

