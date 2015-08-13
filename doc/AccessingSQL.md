
Basics:
-------

Underneath everything is the Ruby Sequel library; there are a number
of ways to access it.

Check out http://ricostacruz.com/cheatsheets/sequel.html or the Sequel
gem docs for details of the sequel library.

Many objects in fixie have the accessor inner, which exposes the
Sequel selector. This includes:
* The constants ORGS, USERS, ASSOCIATIONS, and INVITES
```ruby
ORGS.inner.first
#< @values={:id=>"7ddaee6b42e8f6a0a8e9d5d5efe644f8", :authz_id=>"f46b2e53869968ce115b97d2fd8bfee0", :name=>"ponyville", :full_name=>"ponyville", :assigned_at=>2015-07-21 18:22:34 UTC, :last_updated_by=>"08076ed32f7d5c62721607dd2c309c55", :created_at=>2015-07-21 18:22:34 UTC, :updated_at=>2015-07-21 18:22:34 UTC}>
```
* Any of the by_XXXX accessors
```ruby
ORGS['


```





fixie:0 > o.groups.by_name(cl.id).inner.count
1
fixie:0 > o.groups.by_name(cl.id).inner.delete
1
fixie:0 > o.groups.by_name(cl.id).inner.count     


* Changing email for user in fixie

USERS.by_username('anujbiyani').inner.update(:email=>"anujbiyani01@gmail.com")



* Adding a record
```ruby
u=USERS['a_username']
o=ORGS['an_org']
pivotal = USERS['pivotal']
now = Sequel.function(:NOW)

ASSOCS.inner.insert(:org_id=>o.id, :user_id=>u.id, :last_updated_by=>pivotal.authz_id,
	:created_at=>now, :updated_at=>now )
```


* Fixing a group that lost its authz object.
We've seen the users group in hosted loose it's authz entry

```ruby
a = Fixie::AuthzApi.new
# create a new authz group
g = a.post("groups",{})
# check that only one group is returned
ORGS['acme'].groups.by_name('users').inner.all
# alter the group and insert the new authz id
ORGS['acme'].groups.by_name('users').inner.update(:authz_id=>g.id)
```

This does not add the users back to the usergs group, or re-add users
all the acls that used to have the users group in them.
