# fixie

Low level manipulation tool for Chef Infra Server.

This tool is in its very early stages, and should be used with great care.

## Purpose

Provide a tool to debug and fix low level problems with chef server, especially those surrounding ACLs and
groups. This tool works at an extremely low level, and provides minimal protection against data loss and
corruption. If a problem can be fixed using the API, that should be done instead. This exists for those use
cases where the API can't be used.

## History

For many years orgmapper has been a useful, if somewhat frustrating tool to debug and fix low level problems
with chef server, especially those surrounding ACLs and groups. The tool has never been stable, and has
suffered from somewhat arcane syntax. 

Orgmapper became increasingly broken with the move to use sql instead of couchdb, and the obsolescence of
mixlib-authorization, opscode-account and the rest of the ruby based chef, and became completely useless with
the migration of organizations to SQL. Yet the need for a low level editing tool remains.

## Goals

* Allow the repair of common problems such as organization lockouts, broken ACLs and the like.

* Tests: All functionality should be part of CI, and run as part of nightly tests. We should treat breakage
  of fixie as a issue to be addressed like any other CI failure. 

* Scriptability: We have a collection of scripts for diagnosing and fixing user problems written against
  orgamapper; these scripts should be ported and enhanced to make them more generally useful.


## Documentation

Documentation can be found in in the doc directory, especially the
[doc/GETTING_STARTED.md](doc/GETTING_STARTED.md) file.

## Bugs/Issues/Pull Requests

Please file bugs/issues/pull requests against the [fixie](https://github.com/chef/fixie) repository in
github. 

## License

|                      |                                          |
|:---------------------|:-----------------------------------------|
| **Copyright:**       | Copyright:: Chef Software, Inc.
| **License:**         | Apache License, Version 2.0


All files in the repository are licensed under the Apache 2.0 license. If any file is missing the License
header it should assume the following is attached;

Copyright:: Chef Software Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
