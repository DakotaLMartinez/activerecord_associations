class PlaylistTrack < ActiveRecord::Base
  self.table_name = "PlayListTrack"
  belongs_to :playlist, foreign_key: "PlaylistId"
  belongs_to :track, foreign_key: "TrackId"
end