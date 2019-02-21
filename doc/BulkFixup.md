Restoring acl permissions globally
============

If a key group is deleted (such as users)

* Verify that the org has issues

* Create/restore the group
(TBW)

* Add the users/groups back to the group
(TBW)

* Set the group ACL appropriately
```ruby
users_group.ace_add([:create,:read,:update,:delete], org.groups['admins'])
users_group.ace_add([:create,:read,:update,:delete], USERS['pivotal'])
```

* Restore users to the appropriate container ACLs
```ruby
org = ORGS[THE_ORG]
cl = %w(cookbooks data nodes roles environments policies policy_groups cookbook_artifacts)
cl.each {|c| o.containers[c].ace_add([:create,:read,:update,:delete], org.groups['users']) }
%w(clients).each { |c| org.containers[c].ace_add([:read,:delete], org.groups['users']) }
%w(groups containers).each { |c| org.containers[c].ace_add([:read], org.groups['users']) }
%w(sandboxes).each { |c| org.containers[c].ace_add([:create], org.groups['users']) }
```

* Then update the objects from the containers:
```ruby
Fixie::BulkEditPermissions::copy_from_containers(org)
```
