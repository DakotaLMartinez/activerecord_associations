# ActiveRecord Associations

To get a sense of how ActiveRecord associations work, we'll again refer to the Chinook database we used for the SQL lecture. We'll also be creating our own database later on, but I want to use this database as an example so you can get a sense of how the association macros work with an existing database structure. This is a great opportunity to get a sense of what the `has_many` and `belongs_to` methods actually do with an established database structure. Before we start writing some code, Here's our file structure.

``` to the class
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
│   ├── ar_chinook.sqlite
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
│   │   ├── chinook
│   │   │   ├── album.rb
│   │   │   ├── artist.rb
│   │   │   ├── customer.rb
│   │   │   ├── employee.rb
│   │   │   ├── genre.rb
│   │   │   ├── invoice.rb
│   │   │   ├── invoice_line.rb
│   │   │   ├── media_type.rb
│   │   │   ├── playlist.rb
│   │   │   ├── playlist_track.rb
│   │   │   └── track.rb
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
    database: 'db/ar_chinook.sqlite'
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
- loads all of the files inside of `./lib/activerecord_associations`. If we add files there, this file will load them. So, if we want to add new files for classes that we add, that will work just fine without adding additional `require` statements.

Because this file is required from the `Rakefile` we should have access to the code in all files within `lib/activerecord_associations`  within our `rake chinook` console.

To start, we have a directory called `chinook` inside of `lib/activerecord_associations` that contains a single file for a model corresponding to one of Chinook's database tables. 

So, right away, we should be able to boot up a console and interact with these classes and call ActiveRecord query methods on them.

Okay, now let's boot up the console by running:
```bash
rake chinook
```

Now, let's try to fetch all of the artists:

```rb
Artist.all
D, [2021-07-06T19:14:03.894004 #92451] DEBUG -- :   Artist Load (2.0ms)  SELECT "artists".* FROM "artists"
=> [#<Artist:0x00007fde5597a780 id: 1, name: "AC/DC">,
 #<Artist:0x00007fde559788e0 id: 2, name: "Accept">,
 #<Artist:0x00007fde559787a0 id: 3, name: "Aerosmith">,
 #<Artist:0x00007fde55978660 id: 4, name: "Alanis Morissette">,
 #<Artist:0x00007fde55978520 id: 5, name: "Alice In Chains">,
 #<Artist:0x00007fde559783e0 id: 6, name: "Antônio Carlos Jobim">,
 #<Artist:0x00007fde559782a0 id: 7, name: "Apocalyptica">,
 #<Artist:0x00007fde55978160 id: 8, name: "Audioslave">,
 #<Artist:0x00007fde55978020 id: 9, name: "BackBeat">,
 #<Artist:0x00007fde543abe90 id: 10, name: "Billy Cobham">,
 #<Artist:0x00007fde543abd50 id: 11, name: "Black Label Society">,
 #<Artist:0x00007fde543abc10 id: 12, name: "Black Sabbath">,
```

We can try to find Led Zeppelin too:

```rb
Artist.find_by(name: "Led Zeppelin")
D, [2021-07-06T19:16:14.315974 #92451] DEBUG -- :   Artist Load (4.0ms)  SELECT  "artists".* FROM "artists" WHERE "artists"."name" = ? LIMIT ?  [["name", "Led Zeppelin"], ["LIMIT", 1]]
=> #<Artist:0x00007fde50ba48f8 id: 22, name: "Led Zeppelin">
```

We can also access the database table's structure by invoking `column_names` on the class.

```rb
Artist.column_names
=> ["id", "name"]
```

Now, let's give the `Album` class a shot.

```rb
Album.all
D, [2021-07-06T19:19:36.201331 #92451] DEBUG -- :   Album Load (3.1ms)  SELECT "albums".* FROM "albums"
=> [#<Album:0x00007fde50bd50c0 id: 1, title: "For Those About To Rock We Salute You", artist_id: 1>,
 #<Album:0x00007fde50bd4f58 id: 2, title: "Balls to the Wall", artist_id: 2>,
 #<Album:0x00007fde50bd4e18 id: 3, title: "Restless and Wild", artist_id: 2>,
 #<Album:0x00007fde50bd4c38 id: 4, title: "Let There Be Rock", artist_id: 1>,
 #<Album:0x00007fde50bd4af8 id: 5, title: "Big Ones", artist_id: 3>,
 #<Album:0x00007fde50bd49b8 id: 6, title: "Jagged Little Pill", artist_id: 4>,
 #<Album:0x00007fde50bd4878 id: 7, title: "Facelift", artist_id: 5>,
 #<Album:0x00007fde50bd4738 id: 8, title: "Warner 25 Anos", artist_id: 6>,
 #<Album:0x00007fde50bd45f8 id: 9, title: "Plays Metallica By Four Cellos", artist_id: 7>,
 #<Album:0x00007fde50bd44b8 id: 10, title: "Audioslave", artist_id: 8>,
 #<Album:0x00007fde50bd4378 id: 11, title: "Out Of Exile", artist_id: 8>,
 #<Album:0x00007fde50bd4238 id: 12, title: "BackBeat Soundtrack", artist_id: 9>,
```

And, to check how many there are, we can run a count:

```rb
Album.count
D, [2021-07-06T19:20:19.038096 #92451] DEBUG -- :    (1.1ms)  SELECT COUNT(*) FROM "albums"
=> 347
```

OK, so what if we want only the albums by AC/DC? First, we'll want to find the AC/DC artist:

```rb
artist = Artist.find_by(name: "AC/DC")
D, [2021-07-06T19:21:15.372210 #92451] DEBUG -- :   Artist Load (0.1ms)  SELECT  "artists".* FROM "artists" WHERE "artists"."name" = ? LIMIT ?  [["name", "AC/DC"], ["LIMIT", 1]]
=> #<Artist:0x00007fde551ec888 id: 1, name: "AC/DC">
```

Then we can use this artist's id and match it up with the foreign key on the `albums` table by doing a where query.

```rb
albums = Album.where(artist_id: 1)
D, [2021-07-06T19:22:09.523018 #92451] DEBUG -- :   Album Load (5.3ms)  SELECT "albums".* FROM "albums" WHERE "albums"."artist_id" = ?  [["artist_id", 1]]
=> [#<Album:0x00007fde5521ca10 id: 1, title: "For Those About To Rock We Salute You", artist_id: 1>, #<Album:0x00007fde5521c8d0 id: 4, title: "Let There Be Rock", artist_id: 1>]
```

#### Alert

While it seems like we're looking at an array here, it's actually not an array of Album instances:

```rb
albums.class
=> Album::ActiveRecord_Relation
```

This will be important later on because it means we still have a connection to the Album class and ActiveRecord methods that we can use to make additional queries if we so choose.
## One-to-Many relationships

As you can imagine, managing object relationships is one of the main repetitive tasks that ActiveRecord could provide support for. And, AR does not disappoint! It just so happens that this artist and this album are related in a one-to-many way.

- an album `belongs_to` the artist. 
- an artist `has_many` albums. 

Modeling relationships in ActiveRecord is as simple as describing the relationship! The code reads much like you would say it:

```rb
class Artist < ActiveRecord::Base
  has_many :albums
end
```

Let's try this out. First, exit out of the console, start a new one and try to `Artist.first.albums`:

```rb
albums = Artist.first.albums
D, [2021-07-06T19:28:25.798385 #95393] DEBUG -- :   Artist Load (0.2ms)  SELECT  "artists".* FROM "artists" ORDER BY "artists"."id" ASC LIMIT ?  [["LIMIT", 1]]
D, [2021-07-06T19:28:25.804233 #95393] DEBUG -- :   Album Load (0.1ms)  SELECT "albums".* FROM "albums" WHERE "albums"."artist_id" = ?  [["artist_id", 1]]
=> [#<Album:0x00007ff6bea8fc70 id: 1, title: "For Those About To Rock We Salute You", artist_id: 1>, #<Album:0x00007ff6bea8fb08 id: 4, title: "Let There Be Rock", artist_id: 1>]
```


Awesome! This looks like the same collection we had previously. Let's take a close look at the SQL query generated here and compare it to the previous one.

```rb
# this one
Album Load (0.1ms)  SELECT "albums".* FROM "albums" WHERE "albums"."artist_id" = ?  [["artist_id", 1]]
# previous one
Album Load (5.3ms)  SELECT "albums".* FROM "albums" WHERE "albums"."artist_id" = ?  [["artist_id", 1]]
```

Same query! Is the return value different?

```rb
albums.class
=> Album::ActiveRecord_Associations_CollectionProxy
```

A couple of quick links here:
- [API documentation for ActiveRecord::Relation](https://api.rubyonrails.org/v5.2.6/files/activerecord/lib/active_record/relation_rb.html)
- [API documentation for ActiveRecord::Associations::CollectionProxy](https://api.rubyonrails.org/v5.2.6/classes/ActiveRecord/Associations/CollectionProxy.html)

For right now, all that's important is that you remember that the association methods return something different from the `ActiveRecord::Relation` we get back from `.all` or `.where`. The main reason we would care is that the type of object we're dealing with tells us what methods we can call on it. If you check the docs linked above, you can see that the `ActiveRecord::Associations::CollectionProxy` actually inherits from `Relation`. So, it will have all the same methods that we could call on `Album.all` including additional methods designed to take advantage of the fact that we're dealing with albums that belong to the `AC/DC` artist. You'll be revisiting this topic in greater depth in phase 4.

## Learning how the Magic Works

Just like all the rest of our learnings in ruby so far, we can break everything down to objects, methods, arguments and return values (or side effects). Let's do that here.

```rb
class Artist < ActiveRecord::Base
  has_many :albums
end
```

| Object | Method | Argument | Return Value/side effects |
|---|---|---|---|
| `Artist` | `has_many` | `:albums` | defines methods in the Artist class that help access associated albums. Return value not important, methods main purpose is the side effects (the defined methods) | 

Okay, so if we're looking for documentation, we need to know where this `has_many` method comes from. So, let's think a bit:

- has_many is invoked within the `Artist` class (without an object up front)
- the implicit receive of any method call is what?
- so what object is receiving the call to `has_many`?

**Insert Dramatic Pause Here**
## ................................................................
## ................................................................
## ................................................................
## ................................................................
## ................................................................
## ................................................................
## ................................................................
## ................................................................
## ................................................................
## ................................................................
## ................................................................
## ................................................................
## ................................................................


Once we get an answer, let's hop down into console and try to find the `has_many` method.

```rb
Artist.methods.select{|m| m.to_s.match("has_many")}
=> [:has_many]
```

Okay, so this must have come from somewhere because we didn't define it ourselves. The only thing we have in our Artist class is the `has_many` method call, no definition, so it must be coming from our inheritance relationship with `ActiveRecord::Base`. To check that, we can go looking for it there.

```rb
ActiveRecord::Base.methods.select{|m| m.to_s.match("has_many")}
=> [:has_many]
```

Okay, so we've confirmed that this method is coming from `ActiveRecord::Base`, now let's go look at the docs for [ActiveRecord::Base](https://api.rubyonrails.org/v5.2.6/classes/ActiveRecord/Base.html). At the bottom of this page, there's a list of links to included modules. Including a module within a class adds all of its methods. About 2/3 the way down in the list, you'll see [ActiveRecord::Associations](https://api.rubyonrails.org/v5.2.6/classes/ActiveRecord/Associations.html). There, you'll see a module and a namespace linked at the bottom. Both are relevant when thinking about and working with ActiveRecord association methods:

- [MODULE ActiveRecord::Associations::ClassMethods](https://api.rubyonrails.org/v5.2.6/classes/ActiveRecord/Associations/ClassMethods.html)
- [CLASS ActiveRecord::Associations::CollectionProxy](https://api.rubyonrails.org/v5.2.6/classes/ActiveRecord/Associations/CollectionProxy.html)

To dig into the `has_many` macro itself, we'll want to check out the top link to the `ClassMethods` module. At the top of this doc, this is how the module is described:

>Associations are a set of macro-like class methods for tying objects together through foreign keys. They express relationships like “Project has one Project Manager” or “Project belongs to a Portfolio”. Each macro adds a number of methods to the class which are specialized according to the collection or association symbol and the options hash. It works much the same way as Ruby's own attr* methods.

The key takeaway for right now is that these methods (`has_many` and `belongs_to`) are macro-like methods. So, much like `attr_accessor` the purpose of `has_many` and `belongs_to` is to add methods to the class. In this case, we use the macros to create association methods. I'd strongly recommend bookmarking this web page and revisiting it often over the next few weeks & months. It contains more information and examples than you'll need at first, but over time, you'll get more out of this doc as you revisit and re-read it. The top part of the documentation gives a bunch of examples and different scenarios, while the bottom of the docs describe the association macros, the options you can pass and the affect that they have on the generated methods. This is the part we'll focus on now. Here are links to the docs for the 2 association macros that we'll be using:

- [belongs_to](https://api.rubyonrails.org/v5.2.6/classes/ActiveRecord/Associations/ClassMethods.html#method-i-belongs_to)
- [has_many](https://api.rubyonrails.org/v5.2.6/classes/ActiveRecord/Associations/ClassMethods.html#method-i-has_many)

If we check out the docs for the `has_many` method, we see detailed descriptions of the methods added by the macro, including a list of examples:

#### Example
A Firm class declares has_many :clients, which will add:
```
Firm#clients (similar to Client.where(firm_id: id))

Firm#clients<<

Firm#clients.delete

Firm#clients.destroy

Firm#clients=

Firm#client_ids

Firm#client_ids=

Firm#clients.clear

Firm#clients.empty? (similar to firm.clients.size == 0)

Firm#clients.size (similar to Client.count "firm_id = #{id}")

Firm#clients.find (similar to Client.where(firm_id: id).find(id))

Firm#clients.exists?(name: 'ACME') (similar to Client.exists?(name: 'ACME', firm_id: firm.id))

Firm#clients.build (similar to Client.new(firm_id: id))

Firm#clients.create (similar to c = Client.new(firm_id: id); c.save; c)

Firm#clients.create! (similar to c = Client.new(firm_id: id); c.save!)

Firm#clients.reload
```
The declaration can also include an options hash to specialize the behavior of the association.
>When we use the `has_many` macro in a class, `ActiveRecord` assumes that the class on the other end of that relationship has an all lower case, snake case foreign key matching the name of the calling class followed by `_id`.

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

In our example, check out the query that's generated:

```sql
Artist.first.albums
D, [2021-07-06T23:56:50.669228 #95393] DEBUG -- :   Artist Load (12.5ms)  SELECT  "artists".* FROM "artists" ORDER BY "artists"."id" ASC LIMIT ?  [["LIMIT", 1]]
D, [2021-07-06T23:56:50.705474 #95393] DEBUG -- :   Album Load (0.6ms)  SELECT "albums".* FROM "albums" WHERE "albums"."artist_id" = ?  [["artist_id", 1]]
=> [#<Album:0x00007ff6c20cb2f8 id: 1, title: "For Those About To Rock We Salute You", artist_id: 1>,
 #<Album:0x00007ff6c20ca2b8 id: 4, title: "Let There Be Rock", artist_id: 1>]
```

The foreign key "artist_id" is inferred from the context of the `has_many` method call. Since we called `has_many` within the `Artist` class, ActiveRecord assumes our foreign key will be `artist_id`. The primary key is always assumed to be `id`. This primary key is used within the bound parameter (the ? mark) within the SQL query. We're matching up the primary key value for the artist with the artist_id foreign key for the albums. If we needed to override either of those for any reason, we could pass options to has_many:

```rb
class Artist < ActiveRecord::Base
  has_many :albums, primary_key: "hello", foreign_key: "world"
end
```

```rb
Artist.first.albums
D, [2021-07-07T00:09:42.729226 #45050] DEBUG -- :   Artist Load (0.3ms)  SELECT  "artists".* FROM "artists" ORDER BY "artists"."id" ASC LIMIT ?  [["LIMIT", 1]]
D, [2021-07-07T00:09:42.801076 #45050] DEBUG -- :   Album Load (0.5ms)  SELECT "albums".* FROM "albums" WHERE "albums"."world" = ?  [["world", nil]]
D, [2021-07-07T00:09:42.802363 #45050] DEBUG -- :   Album Load (0.7ms)  SELECT  "albums".* FROM "albums" WHERE "albums"."world" IS NULL LIMIT ?  [["LIMIT", 11]]
=> #<Album::ActiveRecord_Associations_CollectionProxy:0x3fdf330947d0>
```

Notice that this time the foreign_key is "albums"."world" and the bound parameter is `nil` because there is no such primary key "hello". Oddly enough, we don't get an error here, we're just not getting anything back. So, if you're working on an association and feel like you're getting nothing back when you should be seeing something, make sure to take a look at the SQL query it's firing off and take a look at your schema while you're at it. You should be able to see the problem if you put your eyes in those two places side by side.

Overriding the primary key can be useful if you're working with data that you've imported from another database and you need to modify the queries to use primary keys imported from the other database rather than the ones added by active record.

Overriding the foreign key can be useful if your foreign key doesn't match the convention. For example if you wanted to have a post belong to an author, but your class name for the Author is really User. In this case, your foreign key for retrieving all of a user's posts would be author_id:

```rb
class User < ActiveRecord::Base
  has_many :posts, foreign_key: "author_id"
end

class Post < ActiveRecord::Base
  belongs_to :author, class_name: "User"
end
```

## One-to-One relationships

Okay, so we've handled the `has_many` side of the relationship, now we need to attend to the [belongs_to](https://api.rubyonrails.org/v5.2.6/classes/ActiveRecord/Associations/ClassMethods.html#method-i-belongs_to) side. Again, the syntax for this reads much like how you would say it:

```rb
class Album < ActiveRecord::Base
  belongs_to :artist
end
```

Now, let's restart `rake chinook` and try `Album.first.artist`

```rb
Album.first.artist
D, [2021-07-07T00:19:35.985241 #46910] DEBUG -- :   Album Load (0.8ms)  SELECT  "albums".* FROM "albums" ORDER BY "albums"."id" ASC LIMIT ?  [["LIMIT", 1]]
D, [2021-07-07T00:19:36.268457 #46910] DEBUG -- :   Artist Load (0.9ms)  SELECT  "artists".* FROM "artists" WHERE "artists"."id" = ? LIMIT ?  [["id", 1], ["LIMIT", 1]]
=> #<Artist:0x00007f8f431318c8 id: 1, name: "AC/DC">
```

Wonderful! Breaking down that query again, this time we have another SELECT statement, this time we're looking for a match between the `artist_id` foreign key of the album we found (in this case `1` because the first Album's artist_id is `1`) matches the `id` primary key of the `artist`. There's also a limit to the number of results here as we only want one record back. This shouldn't be a problem, because primary keys are unique–so we should only find one artist that matches anyway.

Now we've got two SQL queries. One loading the Album, triggered by `Album.first` and the next loading the associated `Artist` generated when we chain on `.artist`. Belongs to assumes that the foreign key to support the relationship is on the associated table and that it is named `other_model_id`. If the foreign key in Chinook was actually `ArtistId` we would need to specify that by adding the `foreign_key: 'ArtistId'` option when invoking the `belongs_to` macro.

If we need to refer to examples of the different options we can use with `belongs_to`, we can consult [the docs on api.rubyonrails.org](https://api.rubyonrails.org/v5.2.6/classes/ActiveRecord/Associations/ClassMethods.html#method-i-belongs_to) or the [shorter belongs_to docs on APIdock](https://apidock.com/rails/ActiveRecord/Associations/ClassMethods/belongs_to)

### Group Discussion (7-10 minutes)

Take a few minutes to go through the Chinook database and identify as many one-to-many relationships as you can. Try adding them to the classes inside of `lib/activerecord_associations/chinook` and then playing around with instances in the console.

1. Look through the database using SQLITE Explorer
2. Find a one-to-many relationship
3. Add the necessary macros to the appropriate class
4. open `rake chinook` and try out some of the association methods added by your macros

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

An example of this would be our `User` - `Like` - `Tweet` example because there are 2 types of relationship between `User` and `Tweet`. One that's one-to-many, the other that's many-to-many. We'd do this in ActiveRecord like so:

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

Within our chinook classes, we can add a many to many relationship between `Playlist` and `Track` through `PlaylistTrack`

```rb
class Playlist < ActiveRecord::Base
  # add macros for many to many Playlist <=> Track
end

class PlaylistTrack < ActiveRecord::Base
  # add macros for many to many Playlist <=> Track
end

class Track < ActiveRecord::Base
  # add macros for many to many Playlist <=> Track
end
```

And now you're able to access the playlists associated with a track:

```rb
Playlist.last.tracks
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
Track.first.playlists
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

Those methods are simpler and very familiar at this point. The association methods are new and deserve lots of attention and repetition. Here are the places I would bookmark and return to frequently for review:
  - [APIDock belongs_to guide](https://apidock.com/rails/v5.2.3/ActiveRecord/Associations/ClassMethods/belongs_to)
  - [APIDock has_many guide](https://apidock.com/rails/v5.2.3/ActiveRecord/Associations/ClassMethods/has_many)
  - [MODULE ActiveRecord::Associations::ClassMethods on api.rubyonrails.org for greater detail and rigor](https://api.rubyonrails.org/v5.2.6/classes/ActiveRecord/Associations/ClassMethods.html)


I'd recommend referring to documentation virtually every single time you build out associations for the next few months as it's the best way to become quickly familiar with how to handle common scenarios and also to figure out how to handle variations on those scenarios. That said, you'll get a lot of mileage out of a couple of the methods you get from each macro.

- If you do `Artist.has_many :albums`, you're probably going to call the `@artist.albums` method the most.
- If you do `Album.belongs_to :artist`, you're probably going to call the `@album.artist` method the most.
## Exercise

For the exercise, there are 3 migrations written. 2 Are complete, the 3rd you'll need to fill in before running. (The schema version matches the prior migration, so as long as you wait to run `rake db:migrate` until you've completed the migration, it should work fine). If you run rspec, you should see 12 examples, 7 failures.

After completing the migration and running it, running `rspec` should result in 6 passing specs and 6 failing ones. The final 6 tests are for the association macros you'll need to set up. Open up the file `lib/activerecord_associations/many_to_many.rb` and add the associations to the 3 classes defined there. Once you've finished, all tests should pass.

At this point, you can play around with your 3 classes in the console by running `rake console` Try:
- Creating a couple of new tags
- Creating a new Post
- Adding the new tags to an existing post using `post.tags <<` (watch the SQL that gets generated as you do this.)
- Explore other has_many methods as referenced on [APIDock](https://apidock.com/rails/ActiveRecord/Associations/ClassMethods/has_many)
