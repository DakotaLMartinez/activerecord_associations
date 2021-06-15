# ActiveRecord Associations

To get a sense of how ActiveRecord associations work, we'll again refer to the Chinook database we used for the SQL lecture. We'll also be creating our own database later on, but I want to use this database as an example so you can get a sense of how the association macros work with an existing database structure. Because Chinook follows slightly different naming conventions than ActiveRecord expects, we'll also have to override some of the default assumptions that ActiveRecord makes. This is a great opportunity to get a sense of what the `has_many` and `belongs_to` methods actually do. Before we start writing some code, Here's our file structure.

```
├── CODE_OF_CONDUCT.md
├── Gemfile
├── Gemfile.lock
├── LICENSE.txt
├── README.md
├── Rakefile
├── bin
│   ├── console
│   └── setup
├── db
│   ├── Chinook_Sqlite.sqlite
│   ├── migrate
│   │   ├── 20210615143927_create_posts.rb
│   │   ├── 20210615143942_create_tags.rb
│   │   └── 20210615143947_create_post_tags.rb
│   ├── schema.rb
│   └── test.sqlite
├── img
│   └── quick_query_for_ac_dc.png
├── lib
│   ├── activerecord_associations
│   │   ├── album.rb
│   │   ├── artist.rb
│   │   ├── many_to_many.rb
│   │   ├── models.rb
│   │   └── version.rb
│   └── activerecord_associations.rb
└── spec
    ├── activerecord_associations_spec.rb
    └── spec_helper.rb
```

We'll be using `require_all` today to load all files we add in the `lib/activerecord_associations` directory. So, we're free to create multiple files here and trust that they will be accessible to us when we run `rake console`

Also, here's the `Rakefile` to show how we set up the console:

```rb
# Rakefile
require "rspec/core/rake_task"
require "pry"
require "sinatra/activerecord/rake"
require_relative "./lib/activerecord_associations"

desc "starts a console"
task :console do 
  ActiveRecord::Base.establish_connection(
    adapter: 'sqlite3',
    database: 'db/development.sqlite'
  )
  Pry.start
end

desc "chinook console" 
task :chinook do 
  ActiveRecord::Base.establish_connection(
    adapter: 'sqlite3',
    database: 'db/Chinook_Sqlite.sqlite'
  )
  Pry.start
end

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

```

Notice we have two separate console tasks defined here. One of them sets up a connection with a development database, another with the Chinook database. We're doing this so we have the ability to create ActiveRecord models that work with the Chinook database as well as a different one if we so choose. This is somewhat similar to having a test database and development database. It allows us to have a separate playground for certain classes. But, we're actually loading all of our classes every time, so we'll need to be aware of which console is running (and therefore which database we're connected to) as this will inform which classes actually have database backing and which ones don't.

Before we run the `chinook` task to start playing around with the Chinook database using ActiveRecord, let's take a look at the `lib/activrecord_associations.rb` file:

```rb
# lib/activerecord_associations.rb
require "require_all"
require "sinatra/activerecord"
ActiveRecord::Base.logger = Logger.new(STDOUT)
require_all "./lib/activerecord_associations"

module ActiverecordAssociations
  class Error < StandardError; end
  # Your code goes here...
end
```
Currently, this file is serving as our environment file. It's doing the following:
- loading necessary dependencies 
- configuring the logger for `ActiveRecord::Base` to put out SQL interactions to the `STDOUT`. (So we see the SQL generated by our calls to ActiveRecord methods in the console).
- loads all of the files inside of `./lib/activerecord_associations`. If we add files there, this file will load them.

Because this file is required from the `Rakefile` we should have access to the code in all files within `lib/activerecord_associations`  within our `rake chinook` console.

For ease of demonstration, I'm going to put our model classes in a file called `lib/activerecord_associations/models.rb`. But, if you'd like to practice working in separate files, the project is set up in such a way that doing so will work the same way.

So, to start playing around with this Chinook data using ActiveRecord, we can create an `Artist` class and an `Album` class. 

```rb
# lib/activerecord_associations/models.rb
class Artist < ActiveRecord::Base

end

class Album < ActiveRecord::Base

end
```

Okay, now let's boot up the console by running:
```bash
rake chinook
```

Now, let's try to fetch all of the artists:

```rb
Artist.all
D, [2021-06-14T16:27:47.549850 #59390] DEBUG -- :   Artist Load (0.5ms)  SELECT "artists".* FROM "artists"
D, [2021-06-14T16:27:47.550400 #59390] DEBUG -- :   Artist Load (0.2ms)  SELECT  "artists".* FROM "artists" LIMIT ?  [["LIMIT", 11]]
=> #<Artist::ActiveRecord_Relation:0x3fde88dc9050>
```

This is odd, because if we open up our Sqlite Explorer extension we can see that we have artists in the database. The issue in this case is that there is not a table in Chinook called `artists` the table is actually called `Artist`. So, this query isn't yielding results:

```sql
SELECT "artists".* FROM "artists"
```

We get a more helpful error if we try to get the first artist:

```rb
Artist.first
D, [2021-06-14T16:31:09.809434 #59390] DEBUG -- :   Artist Load (0.3ms)  SELECT  "artists".* FROM "artists" ORDER BY "artists"."id" ASC LIMIT ?  [["LIMIT", 1]]
ActiveRecord::StatementInvalid: SQLite3::SQLException: no such table: artists: SELECT  "artists".* FROM "artists" ORDER BY "artists"."id" ASC LIMIT ?
from /Users/dakotamartinez/.rvm/gems/ruby-2.6.6/gems/sqlite3-1.4.2/lib/sqlite3/database.rb:147:in `initialize'
Caused by SQLite3::SQLException: no such table: artists
from /Users/dakotamartinez/.rvm/gems/ruby-2.6.6/gems/sqlite3-1.4.2/lib/sqlite3/database.rb:147:in `initialize'
```

In general, this isn't something you'll need to worry about as you'll just create the table with the appropriate name. But, for this example, we can demonstrate how ActiveRecord's `table_name` method is being used to generate the queries. In this case, we need to set the `table_name` to `Artist` so that these methods work properly. To do that, we need to hop out of the `chinook` console and add to our `Artist` model:

```rb
class Artist < ActiveRecord::Base
  self.table_name = "Artist"
end
```

Now, let's open up the `rake chinook` console again and try `Artist.first`

```rb
[1] pry(main)> Artist.first
D, [2021-06-14T16:34:07.030043 #61531] DEBUG -- :   Artist Load (0.4ms)  SELECT  "Artist".* FROM "Artist" ORDER BY "Artist"."ArtistId" ASC LIMIT ?  [["LIMIT", 1]]
=> #<Artist:0x00007fe1ff5cc9c8 ArtistId: 1, Name: "AC/DC">
```

There we go! Now ActiveRecord is talking to Chinook and allowing us to make queries! Let's keep going by focusing on `Albums` next. If we do this in the console:

```rb
[2] pry(main)> Album.first
D, [2021-06-14T16:35:17.189980 #61531] DEBUG -- :   Album Load (0.2ms)  SELECT  "albums".* FROM "albums" ORDER BY "albums"."id" ASC LIMIT ?  [["LIMIT", 1]]
ActiveRecord::StatementInvalid: SQLite3::SQLException: no such table: albums: SELECT  "albums".* FROM "albums" ORDER BY "albums"."id" ASC LIMIT ?
from /Users/dakotamartinez/.rvm/gems/ruby-2.6.6/gems/sqlite3-1.4.2/lib/sqlite3/database.rb:147:in `initialize'
Caused by SQLite3::SQLException: no such table: albums
from /Users/dakotamartinez/.rvm/gems/ruby-2.6.6/gems/sqlite3-1.4.2/lib/sqlite3/database.rb:147:in `initialize'
```

We get the same error as before but with `albums` instead of `artists` as the table name. So, we can fix this in the same way:

```rb
class Album < ActiveRecord::Base
  self.table_name = "Album"
end
```

Exit out of the console and restart it. Then we can try `Album.first` again:

```rb
[1] pry(main)> Album.first
D, [2021-06-14T16:36:33.544694 #62022] DEBUG -- :   Album Load (0.4ms)  SELECT  "Album".* FROM "Album" ORDER BY "Album"."AlbumId" ASC LIMIT ?  [["LIMIT", 1]]
=> #<Album:0x00007f9c74b697f8 AlbumId: 1, Title: "For Those About To Rock We Salute You", ArtistId: 1>
```

Awesome! Now our Artist class and Album class are both connected to one of the tables in the Chinook database.

## One-to-Many relationships

It just so happens that this artist and this album are related. The Album `belongs_to` the artist. And, presumably, this artist also `has_many` albums. Modeling relationships in ActiveRecord is as simple as describing the relationship! The code reads much like you would say it:

```rb
class Artist < ActiveRecord::Base
  self.table_name = "Artist"
  has_many :albums
end
```

Let's try this out. First, exit out of the console, start a new one and try to `Artist.first.albums`:

```rb
[1] pry(main)> Artist.first.albums
D, [2021-06-14T17:01:26.497048 #66450] DEBUG -- :   Artist Load (0.4ms)  SELECT  "Artist".* FROM "Artist" ORDER BY "Artist"."ArtistId" ASC LIMIT ?  [["LIMIT", 1]]
D, [2021-06-14T17:01:26.547058 #66450] DEBUG -- :   Album Load (0.3ms)  SELECT "Album".* FROM "Album" WHERE "Album"."artist_id" = ?  [["artist_id", 1]]
D, [2021-06-14T17:01:26.547563 #66450] DEBUG -- :   Album Load (0.2ms)  SELECT  "Album".* FROM "Album" WHERE "Album"."artist_id" = ? LIMIT ?  [["artist_id", 1], ["LIMIT", 11]]
=> #<Album::ActiveRecord_Associations_CollectionProxy:0x3ffb915cdb78>
```
Hmm, okay. Well, if we check our Sqlite explorer for what's there using a quick query on the chinook database:

```sql
SELECT * FROM Artist WHERE ArtistId = 1; SELECT * FROM Album WHERE ArtistId = 1;
```

We'll see this:

![AC/DC Albums](/img/quick_query_for_ac_dc.png)

Okay, so there are albums that point to the AC/DC ArtistId. Let's take a closer look at the query that was actually generated by our code:


```rb
SELECT "Album".* FROM "Album" WHERE "Album"."artist_id" = ?  [["artist_id", 1]]
```

Notice that the query includes `"Album"."artist_id"` not `"Album"."ArtistId"`. This is another `ActiveRecord` convention. 

>When we use the `has_many` macro in a class, `ActiveRecord` assumes that the class on the other end of that relationship has an all lower case, snake case foriegn key matching the name of the calling class followed by `_id`.

So, when `ActiveRecord` sees 

```rb
class Artist < ActiveRecord::Base
  has_many :albums 
end
```

It makes a few assumptions:

* You have a class defined somewhere called `Album` (uppercase singular of symbol passed to `has_many`)
* The table associated with the `Album` class has a foreign key of `artist_id` (lower case, snake case name of calling class followed by `_id`)
* You want to use the primary key on the `Artist` class's associated table to match with the foreign key on the `Album` class's associated table.

As you may have guessed, you can override these assumptions if you need to! In this case, we can actually see that the primary key is working properly because it's being included in the query:

```sql
SELECT "Album".* FROM "Album" WHERE "Album"."artist_id" = ?  [["artist_id", 1]]
```
What we need is to adjust the name of the foreign key to match what it's actually called within our Chinook database. In order to allow us to override the defaults, both the `has_many` and `belongs_to` macros allow us to pass a second argument (after the name of the association) which is a hash of options. One of these is fittingly called `foreign_key`. 

```rb
class Artist < ActiveRecord::Base
  self.table_name = "Artist"
  has_many :albums, foreign_key: "ArtistId"
end
```

Test this out by restarting `rake chinook` and then running `Artist.first.albums` again. 

```rb
[1] pry(main)> Artist.first.albums
D, [2021-06-14T17:20:20.997680 #70659] DEBUG -- :   Artist Load (0.4ms)  SELECT  "Artist".* FROM "Artist" ORDER BY "Artist"."ArtistId" ASC LIMIT ?  [["LIMIT", 1]]
D, [2021-06-14T17:20:21.049157 #70659] DEBUG -- :   Album Load (1.0ms)  SELECT "Album".* FROM "Album" WHERE "Album"."ArtistId" = ?  [["ArtistId", 1]]
=> [#<Album:0x00007fac0e99f630 AlbumId: 1, Title: "For Those About To Rock We Salute You", ArtistId: 1>,
 #<Album:0x00007fac0e99efc8 AlbumId: 4, Title: "Let There Be Rock", ArtistId: 1>]
```

This time you're actually getting Albums back!

## One-to-One relationships

Okay, so we've handled the `has_many` side of the relationship, now we need to attend to the `belongs_to` side. Again, the syntax for this reads much like how you would say it:

```rb
class Album < ActiveRecord::Base
  self.table_name = "Album"
  belongs_to :artist
end
```

Now, let's restart `rake chinook` and try `Album.first.artist`

```rb
[1] pry(main)> Album.first.artist
D, [2021-06-14T17:23:03.445490 #71205] DEBUG -- :   Album Load (0.1ms)  SELECT  "Album".* FROM "Album" ORDER BY "Album"."AlbumId" ASC LIMIT ?  [["LIMIT", 1]]
=> nil
```

Hmm, not so much. This SQL statement is a little less helpful as an indicator of what went wrong here. It's only selecting from `"Album"` and not from `Artist` which seems wrong. Given what we know about `ActiveRecord` and the convention over configuration mindset, however, let's assume that we need to tell ActiveRecord to use `ArtistId` as the foreign key. 

```rb
[1] pry(main)> Album.first.artist
D, [2021-06-14T17:26:30.526486 #72010] DEBUG -- :   Album Load (0.5ms)  SELECT  "Album".* FROM "Album" ORDER BY "Album"."AlbumId" ASC LIMIT ?  [["LIMIT", 1]]
D, [2021-06-14T17:26:30.549382 #72010] DEBUG -- :   Artist Load (0.5ms)  SELECT  "Artist".* FROM "Artist" WHERE "Artist"."ArtistId" = ? LIMIT ?  [["ArtistId", 1], ["LIMIT", 1]]
=> #<Artist:0x00007fa0ff064eb8 ArtistId: 1, Name: "AC/DC">
```

Now we've got two SQL queries. One loading the Album, triggered by `Album.first` and the next loading the associated `Artist` generated when we chain on `.artist`. Belongs to assumes that the foreign key to support the relationship is on the associated table and that it is named `other_model_id`. Because the foreign key in Chinook is actually `ArtistId` we had to specify that by adding the `foreign_key` option when invoking the `belongs_to` macro.

## Many to Many relationships

Using ActiveRecord, many to many relationships are modeled by using a combination of `has_many` and `belongs_to` macros. As before in our `User`, `Tweet`, `Like` example, there will be 6 methods that support many to many. This time however, we'll use macros to define them rather than creating them from scratch. We'll go through it step by step, but before that we'll take a moment to look at an overview.

```rb
class ModelOne < ActiveRecord::Base
  has_many :join_models
  has_many :model_twos, through: :join_models
end
class JoinModel < ActiveRecord::Base
  belongs_to :model_one
  belongs_to :model_two
end
class ModelTwo < ActiveRecord::Base
  has_many :join_models
  has_many :model_ones, through: :join_models
end
```

Many to Many will always involve 6 macros: 2 `belongs_to`, 2 `has_many` and 2 `has_many, through`. The join model will have both of the `belongs_to` relationships. Each of the other models will have many of the join and also many of the other through the join. We've already talked about the assumptions `ActiveRecord` is making with respect to `has_many` and `belongs_to`, so let's take a moment here to focus on `has_many, through` and how it's different.

So, with `has_many, through`, `ActiveRecord` is looking to see that the association you're going through exists in the model. For example, this won't work:

```rb
class ModelOne < ActiveRecord::Base
  has_many :model_twos, through: :join_models
  has_many :join_models
end
```
Because the `has_many :join_models` association has to exist before you can use it to define `has_many, through`. 

Next, the association you're creating through the other association must exist in some form on the through model. The association can be `has_many` or `belongs_to`, singular or plural, but it must exist on the through (join) model.

```rb
ModelOne.has_many :model_twos, through: :join_models
# only works because
JoinModel.belongs_to :model_two
```

If you need to change the name of the association to something that doesn't match an association that exists on the join model, then you need to specify the `source` option.

An example of this would be our `User` - `Like` - `Tweet` example because there are 2 types of relationship between `User` and `Tweet`. One that's one-to-many ther other that's many-to-many. We'd do this in ActiveRecord like so:

```rb
class User < ActiveRecord::Base
  has_many :tweets  
  has_many :likes
  has_many :liked_tweets, through: :likes, source: :tweet
  # because the liked_tweet association doesn't exist within the `Like` class, we need to specify `:tweet` as the source of this association so ActiveRecord knows to go through likes and give us tweets back when we call `liked_tweets`.
end
class Like < ActiveRecord::Base
  belongs_to :user
  belongs_to :tweet
end
class Tweet < ActiveRecord::Base 
  belongs_to :user
  has_many :likes
  has_many :likers, through: :likes, source: :user
  # because the likers association doesn't exist within the `Like` class, we need to specify `:user` as the source of this association so ActiveRecord knows to go through likes and give us users back when we call `likers`.
end
```

Within Chinook, we can add a many to many relationship between `Playlist` and `Track` through `PlaylistTrack`

```rb
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
```

And now you're able to access the playlists associated with a track:

```rb
[8] pry(main)> Playlist.last.tracks
D, [2021-06-14T22:31:20.713617 #6066] DEBUG -- :   Playlist Load (0.2ms)  SELECT  "Playlist".* FROM "Playlist" ORDER BY "Playlist"."PlaylistId" DESC LIMIT ?  [["LIMIT", 1]]
D, [2021-06-14T22:31:20.718884 #6066] DEBUG -- :   Track Load (0.4ms)  SELECT "Track".* FROM "Track" INNER JOIN "PlaylistTrack" ON "Track"."TrackId" = "PlaylistTrack"."TrackId" WHERE "PlaylistTrack"."PlaylistId" = ?  [["PlaylistId", 18]]
=> [#<Track:0x00007fda93ea6648
  TrackId: 597,
  Name: "Now's The Time",
  AlbumId: 48,
  MediaTypeId: 1,
  GenreId: 2,
  Composer: "Miles Davis",
  Milliseconds: 197459,
  Bytes: 6358868,
  UnitPrice: 0.99e0>]
```

And then you can also access all the playlist associated with a track:

```rb
[9] pry(main)> Track.first.playlists
D, [2021-06-14T22:31:50.210824 #6066] DEBUG -- :   Track Load (0.2ms)  SELECT  "Track".* FROM "Track" ORDER BY "Track"."TrackId" ASC LIMIT ?  [["LIMIT", 1]]
D, [2021-06-14T22:31:50.216590 #6066] DEBUG -- :   Playlist Load (0.2ms)  SELECT "Playlist".* FROM "Playlist" INNER JOIN "PlaylistTrack" ON "Playlist"."PlaylistId" = "PlaylistTrack"."PlaylistId" WHERE "PlaylistTrack"."TrackId" = ?  [["TrackId", 1]]
=> [#<Playlist:0x00007fda93f0db90 PlaylistId: 1, Name: "Music">,
 #<Playlist:0x00007fda93f0da50 PlaylistId: 8, Name: "Music">,
 #<Playlist:0x00007fda93f0d910 PlaylistId: 17, Name: "Heavy Metal Classic">]
```


## What is a Macro?

>Simply put, a macro is a method that defines other methods. We use a macro to dynamically add functionality to a class in Ruby.

The first macros that you learned about were `attr_reader`, `attr_writer` & `attr_accessor`. Each of these is responsible for adding a method(s) to the class they are invoked within. Those macros are built into the `Class` class, so we can invoke them on any object we wish. 

```rb
[7] pry(main)> [:attr_reader, :attr_writer, :attr_accessor].all?{|m| Class.methods.include?(m) }
=> true
```

This is a bit weird, but bear with me because I want to make a point about ruby syntax that can make things feel more magical than they are:

```rb
[1] pry(main)> String.attr_accessor :secret
=> nil
[2] pry(main)> h = "hello"
=> "hello"
[3] pry(main)> h.secret = "world"
=> "world"
[4] pry(main)> h.secret
=> "world"
[5] pry(main)> h
=> "hello"
```

This is an example of *monkey patching* (the act of extending one of Ruby's built in classes by directly adding a method to it). These syntaxes are functionally identical:

```rb
String.attr_accessor :secret
```
and
```rb
class String
  attr_accessor :secret
end
```
and 
```rb
class String 
  self.attr_accessor :secret
end
```

To illustrate what this is doing, we can store the array of methods in the string class before invoking attr_accessor and then subtract those from the methods on the String class after we invoke it. For this, open up a new console (using `rake console` or `rake chinook` will both work for this but I'm going to do `rake chinook`)

```rb
string_methods = "hello".methods.sort
String.attr_accessor :secret
new_string_methods = "hello".methods.sort
difference = new_string_methods - string_methods

```
And you'll see this as the value for `difference`:
```rb
=> [:secret, :secret=]
```

ActiveRecord's approach is to add functionalty via inheritance. So if we want to see what we get from `ActiveRecord::Base`, we can use a similar approach.

```rb
class Test 
end
class AR < ActiveRecord::Base
end
ar_class_methods = AR.methods.sort - Test.methods.sort
# you will see a seemingly unending list of methods here. 
# In fact there are 448 of them.
ar_class_methods.length
=> 448
```

The association macros are among these:

```rb
[15] pry(main)> ar_class_methods.include?(:has_many)
=> true
[16] pry(main)> ar_class_methods.include?(:belongs_to)
=> true
```

Again, following this same approach, we can take a look at the methods added by has_many by:
- taking one class that invokes `has_many`
- taking another empty class that doesn't invoke `has_many` (we'll make a new one for this)
- creating an instance of each class  and storing them in variables called `with_has_many` and `without_has_many`, respectively.
- subtracting the methods `without_has_many` responds to from the methods that `with_has_many` does.

```rb
class ArtistWithoutHasMany < ActiveRecord::Base
  self.table_name = "Artist"
end
[2] pry(main)> with_has_many = Artist.new
=> #<Artist:0x00007fddf45ffc60 ArtistId: nil, Name: nil>
[3] pry(main)> without_has_many = ArtistWithoutHasMany.new
=> #<ArtistWithoutHasMany:0x00007fddf8116240 ArtistId: nil, Name: nil>
[4] pry(main)> has_many_methods = (with_has_many.methods - without_has_many.methods).sort
=> [:after_add_for_albums,
 :after_add_for_albums=,
 :after_add_for_albums?,
 :after_remove_for_albums,
 :after_remove_for_albums=,
 :after_remove_for_albums?,
 :album_ids,
 :album_ids=,
 :albums,
 :albums=,
 :autosave_associated_records_for_albums,
 :before_add_for_albums,
 :before_add_for_albums=,
 :before_add_for_albums?,
 :before_remove_for_albums,
 :before_remove_for_albums=,
 :before_remove_for_albums?,
 :validate_associated_records_for_albums]
```

Of these, the one we will interact with most frequently *by far* is `:albums`. There are use cases where the `:album_ids` and `:album_ids=` methods are useful as well. Specifically, those can help out with checkbox inputs that are sometimes used with many to many relationships like the one between a `Post` and a `Tag`. If you want to learn more about [the methods added by `has_many`, APIdock](https://apidock.com/rails/ActiveRecord/Associations/ClassMethods/has_many) is where I'd recommend referring for documentation.

One thing in particular that's special here is that when you call `albums` on an `artist` instance, you actually get an [`ActiveRecord::Associations::CollectionProxy`](https://edgeapi.rubyonrails.org/classes/ActiveRecord/Associations/CollectionProxy.html) for the `Album` class. This allows us to invoke methods from ActiveRecord on the collection of `albums` as if it were the `Album` class itself, though we're only concerned with `albums` that belong to the `artist` on which `albums` was invoked. 

We could do the same thing to see what methods `belongs_to` adds to a model.

```rb
class AlbumWithoutBelongsTo < ActiveRecord::Base
  self.table_name = "Album"
end
[2] pry(main)> with_belongs_to = Album.new
=> #<Album:0x00007ff0ff473220 AlbumId: nil, Title: nil, ArtistId: nil>
[3] pry(main)> without_belongs_to = AlbumWithoutBelongsTo.new
=> #<AlbumWithoutBelongsTo:0x00007ff1029fc590 AlbumId: nil, Title: nil, ArtistId: nil>
[4] pry(main)> belongs_to_methods = (with_belongs_to.methods - without_belongs_to.methods).sort
=> [:artist,
 :artist=,
 :autosave_associated_records_for_artist,
 :belongs_to_counter_cache_after_update,
 :build_artist,
 :create_artist,
 :create_artist!,
 :reload_artist]
```

Of these, the first, `:artist` will be used most frequently, though there are cases where you'll want `artist=` as well. Sometimes `build_artist` will be useful, though this is less likely if you're using react as a frontend.

## Exercise

For the exercise, there are 3 migrations written. 2 Are complete, the 3rd you'll need to fill in before running. (The schema version matches the prior migration, so as long as you wait to run `rake db:migrate` until you've completed the migration, it should work fine). If you run rspec, you should see 12 examples, 7 failures.

After completing the migration and running it, running `rspec` should result in 6 passing specs and 6 failing ones. The final 6 tests are for the association macros you'll need to set up. Open up the file `lib/activerecord_associations/many_to_many.rb` and add the associations to the 3 classes defined there. Once you've finished, all tests should pass.

At this point, you can play around with your 3 classes in the console by running `rake console` Try:
- Creating a couple of new tags
- Creating a new Post
- Adding the new tags to an existing post using `post.tags <<` (watch the SQL that gets generated as you do this.)
- Explore other has_many methods as referenced on [APIDock](https://apidock.com/rails/ActiveRecord/Associations/ClassMethods/has_many)
