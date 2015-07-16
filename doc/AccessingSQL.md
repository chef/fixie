
Basics:
-------

Underneath everything is the Ruby Sequel library; there are a number
of ways to access it.

Check out http://ricostacruz.com/cheatsheets/sequel.html and 





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
