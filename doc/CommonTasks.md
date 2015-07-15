


Automated organization checkup
----------

If you don't know what's up with an org, there are a few easy starting
points

First of all, run the automated org association checker:

fixie:0 > Fixie::CheckOrgAssociations.check_associations("acme")
Org acme is ok (6 users)

If it reports a problem with a user, you may be able to fix it
automatically:

fixie:0 > Fixie::CheckOrgAssociations.fix_association("acme", "mary")

This might need to be run multiple times to fix all of the errors.
