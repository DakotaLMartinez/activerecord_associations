class Album < ActiveRecord::Base
  self.table_name = "Album" # use Album instead of albums as table name when making SQL queries.
  belongs_to :artist, foreign_key: "ArtistId"
end