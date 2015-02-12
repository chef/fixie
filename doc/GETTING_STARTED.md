
Installing fixie 
-------
In the fixie directory, run `bundle install --binstubs`

Configuring fixie
-------
You need a fixie.conf file with the appropriate URIs and secrets for
accessing postgres and bifrost.

The fixie.conf.example file contains examples from a instance of
private chef.

| Attribute | Description | Example |
|-----------|-------------|---------|
| authz_uri | The URI for the bifrost/authz service | http://localhost:9463 |
| superuser\_id | The authz superuser id | fa84f0f5524a06baaa10b0f988ff2d8f |
| sql\_database | A Ruby Sequel compatible database URI with user and password | postgres://opscode_chef:3b2bb8affc0b87233130f820443aecca2061fadc6c0df16828233e433877ca1c552d1b9d40d3971f0e8c21fc4b7ff9471d91@localhost/opscode_chef |

Running fixie
------
bin/fixie fixie.conf


Inspecting objects
------

There are two core class hierarchies in fixie, one corresponding to a
table (e.g. Orgs), and another corresponding to a row in the table
(e.g. Org). The naming convention is that the plural refers to the
table and the singular refers to the row. These are tightly coupled,
and generally if one exists the other will too.

The table class (e.g. Orgs) provides access to the raw Sequel
objects. There are several constants in the REPL containing
pre-initialized instances of the commonly accessed table classes,
including ORGS, USERS, ASSOCIATIONS, and INVITES.

#### Standard accessors

Each of these have accessors to search by various columns. These use the naming pattern #by\_XXXX, where XXX is the column name in the database. For example ORGS.by\_name('ponyville') searches for the org named 'ponyville'. The return value from this accessor is a new instance of the object that can be further refined. In many cases aliases have been added to hide naming quirks. For example groups use the 'groupname' column, but they can also be accessed using the #by\_name function. 

The REPL supports method completion, so the list of supported filters can be found by typing `ORGS.by_` and hitting the tab key. 

To get a list of all objects selected use the #all method. To list the names of the objects use the #list
method:

```ruby
fixie:0 > ORGS.list
["acme", "ponyville", "wonderbolts"]
fixie:0 > ORGS.all
[#<Fixie::Sql::Org:0x00000003886fa0 @data=#< @values={:id=>"ca0542c21119786fd4d2ddeb5c920ecf", :authz_id=>"baefe78d2fdab7d31fce7f4bdd6feda8", :name=>"ponyville", :full_name=>"ponyville", :assigned_at=>2015-02-05 03:06:33 UTC, :last_updated_by=>"9f6f823739fe6417b1c247ca0d2afdfc", :created_at=>2015-02-05 03:06:33 UTC, :updated_at=>2015-02-05 03:06:33 UTC}>>, #<Fixie::Sql::Org:0x00000003886f50 @data=#< @values={:id=>"2742f6f01ae95aa5998fd7ad94e0d383", :authz_id=>"52064f4a67a2b6c0243051e9f855699a", :name=>"wonderbolts", :full_name=>"wonderbolts", :assigned_at=>2015-02-05 03:07:05 UTC, :last_updated_by=>"9f6f823739fe6417b1c247ca0d2afdfc", :created_at=>2015-02-05 03:07:05 UTC, :updated_at=>2015-02-05 03:07:05 UTC}>>, #<Fixie::Sql::Org:0x00000003886f28 @data=#< @values={:id=>"0434803f600f1688707081921cf92721", :authz_id=>"b9a9dee90b6c2ab31cf4350aeba59460", :name=>"acme", :full_name=>"acme", :assigned_at=>2015-02-05 03:07:32 UTC, :last_updated_by=>"9f6f823739fe6417b1c247ca0d2afdfc", :created_at=>2015-02-05 03:07:32 UTC, :updated_at=>2015-02-05 03:07:32 UTC}>>]
```

The #all and #list functions have protection against accidentally grabbing the entire table; if too many
results are included (currently 10), it returns `:too_many_results` instead. Providing a parameter to the #all
and #list function adjusts the limit.

Any object that has a well defined 'name' has the index ('[]') accessor provided; this takes a string and
returns a single exact match for it if it exists.

#### Predefined objects
* USERS

This allows access to the users table in sql. 

To get the user named 'rainbowdash'
```ruby
> u = USERS['rainbowdash']
#<Fixie::Sql::User:0x00000002afea18 @data=#< @values={:id=>"0000000000004d3eac4cc85b2bdddd0f", :authz_id=>"070dc1cd727a6b71e48d5e16f8d7b137", :username=>"rainbowdash", :email=>"rainbowdash@ponyville.com", :pubkey_version=>0, :public_key=>"-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAr0ZeWeIuU+rO2m1Pe8Nk\n7kzkqmk+CbaP8CVc0OlPZZITgoW2NEseCg1N3FVrCGIIY8vhDkyPST7ZKNva/hOo\nltC8inN695wRchQ1EDpVityL7EIuu7haXBib2WA2HQezlRWKMdrMGGRq0bMa3lD4\nV/YfEXSBtkE8W7QaanbtpgipWC1VGorj0MLR+++JYGd9kqGp49DiC7FH+DChE6pj\nRD9d25/chclD+svZy7RW0s2Q0/H/qRjhOdHoBGljJohVF64CsfqhDCr02zytbKDy\n6sOFjFneSqDZhlx81uVtQ0l+H+0bx77zbwLtp/WjpUFjw/yA8V92/WCjvwMTUaRN\nxQIDAQAB\n-----END PUBLIC KEY-----\n\n", :serialized_object=>"{\"display_name\":\"rainbowdash pony\",\"first_name\":\"rainbowdash\",\"last_name\":\"pony\",\"middle_name\":\"\"}", :last_updated_by=>"c8bd48b83f61031c29ab4ff5168fccd2", :created_at=>2014-10-31 16:59:37 UTC, :updated_at=>2014-10-31 16:59:37 UTC, :external_authentication_uid=>nil, :recovery_authentication_enabled=>false, :admin=>false, :hashed_password=>"$2a$12$FZMrxfVxWLpj8xPiBXG6SO2YxqGMp3zAj7I4w7cr50y1VbCbgIrUe", :salt=>"$2a$12$FZMrxfVxWLpj8xPiBXG6SO", :hash_type=>"bcrypt"}>>
```


To see just the name of that user: 
```ruby
> u.name
"rainbowdash"
```

To find all users with ponyville in their name:
```ruby
> USERS.by_email(/ponyville/)
#<Fixie::Sql::Users:0x00000003514200 @inner=#<Sequel::Postgres::Dataset: "SELECT * FROM \"users\" WHERE (\"email\" ~ 'ponyville')">>
```

Note this returns a users table object which can be refined
further. To process the list of users selected, use the #all method:
```ruby
> USERS.by_email(/ponyville/).all.map {|x| x.name }
["rainbowdash", "fluttershy", "applejack", "pinkiepie", "twilightsparkle", "rarity"]
```

To further refine the set of objects further selectors can be applied:
```ruby
fixie:0 > USERS.by_email(/ponyville/).by_username(/apple/).all.first.name
"applejack"
```

The #all method has a hidden limit (which may be changed in future versions). It has takes a paramenter max\_count (defaults to 10). If it will return more than max\_count elements it returns :too\_many\_results instead; this is to prevent filling the screen or slammming the database by accident.
```ruby
fixie:0 > USERS.all
:too_many_results
```
* ORGS

ORGS work very similarly to USERS, but the org object return also adds accessors for org scoped objects such as nodes, roles, groups, containers, etc.

```ruby
fixie:0 > ORGS['ponyville'].full_name
"ponyville"

fixie:0 > ORGS['ponyville'].groups.all.map {|x| x.name}
["admins", "billing-admins", "clients", "0000000000004d3eac4cc85b2bdddd0f", "000000000000506ccf528a2844e81838", "000000000000808da6731453e12eb2bb", "000000000000dfccddd011ce219caaf0", "00000000000036639a19f27527b29a3e", "000000000000224a1c0e395b112c1d20", "users"]
```

* ASSOCS
* INVITES
* GLOBAL\_GROUPS
* GLOBAL\_CONTAINERS

Altering ACLs and Groups
-----------


#### Editing ACLs

The objects returned by the above selectors have accessors to allow editing of acl and group membership.

ACLs can be viewed for any object
```ruby
fixie:0 > ORGS['ponyville'].clients['ponyville-validator'].acl
{"create"=>{"actors"=>[[:global, "pivotal"]], "groups"=>[["ponyville", "admins"]]}, "read"=>{"actors"=>[[:global, "pivotal"]], "groups"=>[["ponyville", "admins"], ["ponyville", "users"]]}, "update"=>{"actors"=>[[:global, "pivotal"]], "groups"=>[["ponyville", "admins"]]}, "delete"=>{"actors"=>[[:global, "pivotal"]], "groups"=>[["ponyville", "admins"], ["ponyville", "users"]]}, "grant"=>{"actors"=>[[:global, "pivotal"]], "groups"=>[["ponyville", "admins"]]}}
```

Individual ACEs can be viewed

```ruby
fixie:0 > ORGS['ponyville'].clients['ponyville-validator'].ace(:read)
{"actors"=>[[:global, "pivotal"], [:global, "fluttershy"]], "groups"=>[["ponyville", "admins"], ["ponyville", "users"]]}
```

Users and groups can be added to an ACE. The APIs are 'magic' in the sense that they can take an object and figure out if it is an actor or group and add it appropriately.

```ruby
fixie:0 > ORGS['ponyville'].clients['ponyville-validator'].ace_add(:read, USERS['fluttershy'])
    {}
fixie:0 > ORGS['ponyville'].clients['ponyville-validator'].ace_add(:read, GLOBAL_GROUPS['ponyville_global_admins'])
{}
fixie:0 > ORGS['ponyville'].clients['ponyville-validator'].ace(:read)
{"actors"=>[[:global, "pivotal"], [:global, "fluttershy"]], "groups"=>[["ponyville", "admins"], ["ponyville", "users"], ["unknown-00000000000000000000000000000000", "ponyville_global_admins"]]}
```

And removed:
```ruby
fixie:0 > ORGS['ponyville'].clients['ponyville-validator'].ace_delete(:read, GLOBAL_GROUPS['ponyville_global_admins'])
{}
fixie:0 > ORGS['ponyville'].clients['ponyville-validator'].ace(:read)
{"actors"=>[[:global, "pivotal"], [:global, "fluttershy"]], "groups"=>[["ponyville", "admins"], ["ponyville", "users"]]}
fixie:0 > ORGS['ponyville'].clients['ponyville-validator'].ace_delete(:read, USERS['fluttershy'])
{}
fixie:0 > ORGS['ponyville'].clients['ponyville-validator'].ace(:read)
{"actors"=>[[:global, "pivotal"]], "groups"=>[["ponyville", "admins"], ["ponyville", "users"]]}
```

There are also _raw versions of these functions that work on the raw authz ids
```ruby
fixie:0 > ORGS['ponyville'].clients['ponyville-validator'].acl_raw
{"create"=>{"actors"=>["c8bd48b83f61031c29ab4ff5168fccd2"], "groups"=>["ca0a8cabaafaae658edd298ddd4266cd"]}, "read"=>{"actors"=>["c8bd48b83f61031c29ab4ff5168fccd2"], "groups"=>["ca0a8cabaafaae658edd298ddd4266cd", "690063dd87f110eabfa5ba387b8e280f"]}, "update"=>{"actors"=>["c8bd48b83f61031c29ab4ff5168fccd2"], "groups"=>["ca0a8cabaafaae658edd298ddd4266cd"]}, "delete"=>{"actors"=>["c8bd48b83f61031c29ab4ff5168fccd2"], "groups"=>["ca0a8cabaafaae658edd298ddd4266cd", "690063dd87f110eabfa5ba387b8e280f"]}, "grant"=>{"actors"=>["c8bd48b83f61031c29ab4ff5168fccd2"], "groups"=>["ca0a8cabaafaae658edd298ddd4266cd"]}}
```

#### Editing groups

Groups can be viewed:
```ruby
fixie:0 > ORGS['ponyville'].groups['admins'].group
{"actors"=>[[:global, "pivotal"]], "groups"=>[]}
```

Members can be added/removed from groups:
```ruby
fixie:0 > ORGS['ponyville'].groups['admins'].group_add(USERS['fluttershy'])
{}
fixie:0 > ORGS['ponyville'].groups['admins'].group_delete(USERS['fluttershy'])
{}
```

Again there are raw functions that take raw authz ids.
```ruby
fixie:0 > ORGS['ponyville'].groups['admins'].group_raw
{"actors"=>["c8bd48b83f61031c29ab4ff5168fccd2"], "groups"=>[]}
```

 
