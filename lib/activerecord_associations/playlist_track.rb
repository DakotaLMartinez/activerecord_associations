class PlaylistTrack < ActiveRecord::Base
  self.table_name = name
  belongs_to :playlist, foreign_key: "PlaylistId"
  belongs_to :track, foreign_key: "TrackId"
end