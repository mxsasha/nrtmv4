# Near Real Time Mirroring (NRTM) version 4


## Introduction

The Internet Routing Registry (IRR) consists of several different
IRR Databases, each storing objects in the Routing Policy Specification
Language (RPSL). About a dozen larger IRR Databases are widely used,
operated by different organisations, like RIRs and some large network operators.
IRR objects serve many purposes, ranging from manual research by operators to
automated network configuration and filtering.

Most of the IRR Databases mirror RPSL objects from some others, so that queries
run against these instances provide a comprehensive view. Some parties also
mirror IRR Databases to private IRR server instances, to reduce latency in
queries, analyse IRR objects, or other purposes.

Currently mirroring is mainly performed using NRTM version 3 and publication
of files on FTP servers. There are significant issues with this setup.
The protocol specification is unclear, causing interoperability issues,
it is difficult to scale, many issues can cause silent reliability issues,
and security features are absent.

NRTM version 4 is designed to address issues in IRR Database mirroring.
In NRTMv4, IRR Databases publish their records on a HTTPS endpoint,
with periodic Snapshot Files and regular Delta Files. Signing allows integrity
checks. By only generating files once and publishing them over HTTPS,
scalability is dramatically improved.
It borrows extensively from concepts from RRDP, as there are overlaps between
the two protocols.


## Informal Overview

In NRTMv4, a mirror server is an instance of IRR Database software that has
a database of RPSL objects and publishes them to allow mirroring by others.
This can be retrieved by mirror clients, which then load the RPSL objects
into their local databases.

Publication consists of three different files:

* A single Update Notification File. This specifies the current Database version,
  and locations of the Snapshot File and Delta Files. Additionally, there is
  an Update Notification Signature File, used to verify the authenticity of
  the Update Notification File.
* A single active Snapshot File. This contains all published RPSL objects at
  a particular version. The mirror server periodically generates a new snapshot.
* Zero or more Delta Files. These contain the changes between two database
  versions.

Mirror clients initially retrieve the Update Notification File and a Snapshot
File, from which they initialise their local copy of the Database.
After that, mirror clients only need to retrieve the Update Notification File
periodically to determine whether there are any changes,
and then retrieve only the relevant Delta Files. This minimises data transfer.
Deltas have sequential versions.

A mirror client is configured with a public signing key which it uses to verify
the Update Notification File, which in turn contains hashes of all the
Snapshot and Delta Files.

Upon initialization, the mirror server generates a session ID for the Database.
This is used by the client to know that the Delta Files continue to form a
full set of changes allowing clients to update to the latest version. If the
mirror server loses partial history or the mirror client starts mirroring from
a different server, the session ID change will force a full reload from the
latest Snapshot File, ensuring there are no accidental mirroring gaps.

Mirror servers can use caching to reduce their load, particularly because
snapshots and deltas are immutable for a given session ID and version number.
These are also the largest files. Update Notification Files may not be
cached for longer than one minute.

Note that in NRTMv4, a contiguous version number is used for the Database
version and Delta Files. This is different and unrelated to the serial in
NRTMv3. NRTMv3 serials refer to a single change to a single object, whereas
a NRTMv4 version refers to one delta, possibly containing multiple changes to
multiple objects. NRTMv3 serials can also contain gaps, NRTMv4 versions may not.

## Mirror server use

### Key Configuration

When enabling NRTMv4 exports for an IRR Database, an operator MUST configure
a private Ed25519 key to be used for Update Notification Signature Files.

It is RECOMMENDED that implementations provide easily accessible tools for
operators to generate new Ed25519 keys to enter into their configuration, and
generate the public keys from the current configuration. Configuration options
SHOULD be clearly named to indicate that they are private keys.

### Snapshot Initialisation

A mirror server MUST follow the initialisation steps upon the first export
for an IRR Database by that mirror server or if the server lost history and
can not reliably produce a continuous set of deltas from a previous state.

In other words, either the mirror server guarantees that clients following the
deltas have a correct and complete view, or MUST reinitialise, which will
force clients to reinitialise as well.

Initialisation consists of these actions:

* The mirror server MUST generate a new session ID. This MUST be a random v4 UUID.
* The server MUST generate a snapshot for version number one. This may contain
  an empty array of objects if the IRR database is currently empty.
* The server MUST generate a new Update Notification File with the new session
  ID, a reference to the new snapshot, and no deltas.
* The Update Notification Signature File MUST be updated for the new
  Update Notification File contents.

Note that session IDs, versions and all files always relate to a specific IRR
Database. For example, a mirror server publishing NRTMv4 for RIPE and
RIPE-NONAUTH, will generate two Update Notification Files,
referring two Snapshot Files, and two sets of Delta Files each with contiguous
version numbers - all completely independent from each other,
with different session IDs,
even if the same IRR server instance produces both.

### Publishing updates

#### Delta Files

Changes to IRR objects MUST be recorded in Delta Files.
One Delta File can contain multiple changes.

Updates are generated as follows:

* A mirror server MUST publish a Delta File approximately every minute, if
  there have been changes to IRR objects in that time frame.
* If multiple changes have occurred within the time frame that would cancel
  each other out, like an addition and immediate deletion of the same object,
  the mirror server MUST still include all these changes.
* If a mirror server is lagging in production of Delta Files, such as after an
  initialisation or server downtime, it MUST generate one larger "catch up"
  Delta File, rather than individual Delta Files for every one minute window.
* A new Delta File MUST be generated with a new version, one greater than the
  last Delta File version, or one greater than the last Snapshot File version
  if there were no prior deltas at all.
* The Delta File MUST include all changes that happened during the time frame,
  in the order in which they occurred.
* The URL where the Delta File is published MUST contain the session ID and
  version number to allow it to be indefinitely cached.
* The Update Notification File MUST be updated to include the new Delta File and
  update the version.
* The Update Notification Signature File MUST be updated for the new
  Update Notification File contents.

#### Snapshot Files

Snapshot Files after initialisation are generated as follows:

* The mirror server MUST generate a new Snapshot File between once per hour and
  once per day, if there have been changes to the IRR objects.
* The version number of the new snapshot MUST be equal to the last Delta File
  version.
* If there have been no changes to the IRR objects since the last snapshot,
  the mirror server MUST NOT generate a new snapshot.
* The URL where the Snapshot File is published MUST contain the session ID and
  version number to allow it to be indefinitely cached.
* If, after generating the Snapshot File, the total size of all current Delta
  Files up to the snapshot version, exceeds the size of the snapshot, older
  Delta Files MUST be removed, until the total size of the deltas is less than
  the size of the snapshot. This avoids mirror clients downloading more data
  than necessary.
* The Update Notification File MUST be updated to include the new snapshot,
  if one was generates.
* The Update Notification Signature File MUST be updated for the new
  Update Notification File contents.

### Publication Policy Restrictions

A mirror server MAY have a policy that restricts the publication of certain
RPSL objects or attributes, or modifies these before publication.
Typical scenarios for this include preventing the distribution of certain
personal data or password hashes. It is RECOMMENDED to modify objects in such
a way that this change is evident to humans reading the object text, for example
by adding remark lines.

Mirror servers are RECOMMENDED to remove password hashes from the auth lines
in mntner objects, as they have little use beyond the authoritative server,
and their publication may be a security risk.

If a mirror server has a policy that restricts or modifies object publication,
this MUST be applied consistently to Snapshot Files and Delta Files from the
moment the policy is enacted or modified.


## Mirror client use

### Initialisation from snapshot

Mirror clients are configured with the URL to an Update Notification File,
the name of the IRR Database to mirror, and the public key of the IRR Database.
Clients MUST NOT allow mirroring to be configured when one of these settings
is missing.

Clients MUST initialise from a snapshot when initially configured, or if
they are not able to update their local data from the provided Delta Files.

* The client MUST retrieve the Update Notification File.
* The client MUST verify that the source attribute in the Update Notification
  File matches the configured IRR Database name.
* The client MUST retrieve the snapshot and load the objects into its local
  storage.
* The mirror client MUST verify that the hash of the
  Snapshot File matches the hash on the Update Notification
  File that referenced it.  In case of a mismatch of this hash, the
  file MUST be rejected.
* The client MUST record the configured URL and the
  session_id and version from the Update Notification File.

### Processing Delta Files

If a mirror client has previously initialised from a snapshot:

* The client MUST verify that the configured Update Notification File URL matches
  the previously known URL. If this does not match, the client MUST reinitialise
  from the Snapshot File, using the new Update Notification File URL.
* The client MUST retrieve the Update Notification File.
* The client MUST verify that the session ID matches the previously known
  session ID. If this does not match, the client MUST reinitialise from the
  snapshot.
* The client MUST verify that the Update Notification File version is the same
  or higher than the client's current most recent version, to the latest
  version in the Update Notification File. If not, the Update Notification File
  MUST be rejected.
* The client MUST verify that the Update Notification File contains one contiguous set
  of Delta File versions from the client's current most recent version, to the latest
  version in the Update Notification File.
  If this is not found, the client MUST reinitialise from the snapshot.
* The client MUST retrieve all Delta Files for versions since the client's
  last known version, if there are any.
* The mirror client MUST verify that the hash of each newly downloaded
  Delta File matches the hash on the Update Notification
  File that referenced it. In case of a mismatch of this hash, the
  Delta File MUST be rejected.
* The client MUST process all changes in the Delta Files, in order
  of their version number.
* The client MUST update its most recent version to the version of the
  Update Notification File.

If the Update Notification File or one of the Delta Files is rejected, the
mirror client MUST NOT process any newer Deltas than those that are valid
and have been successfully verified.

### Signature Verification

Every time a mirror client retrieves a new version of the Update Notification
File, it MUST retrieve and verify the signature.
The signature MUST be valid for the configured public key for the contents of
the Update Notification File.
If the signature does not match, the mirror client MUST reject the Update
Notification File.

### Policy Restrictions

A mirror client MAY have a policy that restricts the processing of
objects to certain object classes, or other limitations on which objects
it processes.

If a mirror client has a policy that restricts object processing,
this MUST be applied consistently to Snapshot Files and Delta Files from the
moment the policy is enacted or modified.


## Update Notification File

### Purpose

The Update Notification File is used by mirror clients to discover
whether any changes exist between the state of the IRR Database and the
mirror client's state. It also describes the location of the files
containing the snapshot and incremental deltas.

The mirror server MUST generate a new Update Notification File every time
there are new deltas or snapshots.

### Cache concerns

A mirror server may use caching infrastructure to cache the
Update Notification File and reduce the load of HTTPS requests.

However, since this file is used by mirror clients to determine
whether any updates are available, the mirror server SHOULD
ensure that this file is not cached for longer than oen minute. An
exception to this rule is that it is better to serve a stale Update
Notification File rather than no Update Notification File.

### File format and validation

Example Update Notification File:

```
{
  "nrtm_version": 4,
  "type": "notification",
  "source": "EXAMPLE",
  "session_id": "ca128382-78d9-41d1-8927-1ecef15275be",
  "version": 3,
  "snapshot": {
    "version": 2,
    "url": "https://example.com/ca..be/nrtm-snapshot.2.json",
    "hash": "9a..86"
  }
  "deltas": [
    {
      "version": 1,
      "url": "https://example.com/ca..be/nrtm-delta.1.json",
      "hash": "62..a2"
    }
    {
      "version": 2,
      "url": "https://example.com/ca..be/nrtm-delta.2.json",
      "hash": "25..9a"
    }
    {
      "version": 3,
      "url": "https://example.com/ca..be/nrtm-delta.3.json",
      "hash": "b4..13"
    }
  ]
}
```

Note: URIs and hash values in this example are shortened because of
formatting.

The following validation rules MUST be observed when creating or
parsing Update Notification Files:

* The nrtm_version MUST be 4.
* The type MUST be "notification".
* The source MUST be a valid RPSL name.
* The session_id attribute MUST be a random v4 UUID unique to this session
  for this source.
* The version MUST be an unsigned positive integer and be equal to the highest
  version of the deltas and snapshot.
* The file MUST contain exactly one snapshot.
* The file MAY contain one or more deltas.
* The deltas MUST have a sequential contiguous set of version numbers.
* Each snapshot and delta element MUST have a version, URL and hash attribute.
* The hash attribute in snapshot and delta elements MUST be the
  hexadecimal encoding of the SHA-256 hash of the referenced
  file. The mirror client MUST verify this hash when the file is
  retrieved and reject the file if the hash does not match.
* The file MUST be UTF-8 encoded.

### Signature

The contents of Update Notification File MUST be signed using Ed25519. The
public key for this signature must be published by the operator of the mirror
server. The signature of the Update Notification File MUST be published under
the same path as the Update Notification File, appending .sig.

The signature file contains the 64 byte Ed25519 signature, hexadecimal encoded,
on a single line.

## Snapshot File

### Purpose

The Snapshot File reflects the complete and current contents of all RPSL objects
in an IRR Database. Mirror clients use this to initialise their local copy
of the IRR Database.

### Cache Concerns

A snapshot reflects the content of the IRR Database at a specific point
in time; for that reason, it can be considered immutable data.
Snapshot Files MUST be published at a URL that is unique to the
specific session and version.

Because these files never change, they MAY be cached indefinitely.
However, as snapshots are large and old snapshots will no longer be referred by
newer Update Notification Files, it is RECOMMENDED that a limited interval
is used in the order of hours or days.

To avoid race conditions where a mirror client retrieves an Update
Notification File moments before it's updated, mirror servers
SHOULD retain old Snapshot Files for at least 5 minutes after a new
Update Notification File is published.

### File format and validation

Example Snapshot File:

```
{
  "nrtm_version": 4,
  "type": "snapshot",
  "source": "EXAMPLE",
  "session_id": "ca128382-78d9-41d1-8927-1ecef15275be",
  "version": 2,
  "objects": [
    "route: 192.0.2.0/24\norigin: AS65530\nsource: EXAMPLE",
    "route: 2001:db8::/32\norigin: AS65530\nsource: EXAMPLE"
  ]
}
```

Note: RPSL object texts in this example are shortened because of
formatting.

The following validation rules MUST be observed when creating or
parsing Snapshot Files:

* The nrtm_version MUST be 4.
* The type MUST be "snapshot".
* The source MUST be a valid RPSL name, matching the Update Notification File.
* The session_id attribute MUST be a random v4 UUID unique to this session
  for this source, matching the Update Notification File.
* The version MUST be an unsigned positive integer, matching the Update
  Notification File entry for this snapshot.
* The objects attribute MUST be an array of zero or more elements, each
  containing a string representation of an RPSL object.
* The source attribute in the RPSL object texts MUST match the source attribute
  of the Snapshot File.
* The file MUST be UTF-8 encoded.


## Delta File

### Purpose

A Delta File contains all changes for exactly one incremental update of the
IRR Database. It may include new, modified and deleted objects. Delta Files
can contain multiple updates to multiple objects.

### Cache Concerns

Deltas reflects the difference in content of the IRR Database from one version
to another; for that reason, it can be considered immutable data.
Delta Files MUST be published at a URL that is unique to the
specific session and version.

To avoid race conditions where a mirror client retrieves an Update
Notification File moments before it's updated, mirror servers
SHOULD retain old Delta Files for at least 5 minutes after a new
Update Notification File is published that no longer contains these
Delta Files.

### File format and validation

```
{
  "nrtm_version": 4,
  "type": "delta",
  "source": "EXAMPLE",
  "session_id": "ca128382-78d9-41d1-8927-1ecef15275be",
  "version": 3,
  "changes": [
    {
      "action": "delete",
      "existing_object": "route: 192.0.2.0/24\norigin: AS65530\nsource: EXAMPLE",
    }
    {
      "action": "add_modify",
      "new_object": "route: 2001:db8::/32\norigin: AS65530\nsource: EXAMPLE",
    }
  ]
}
```

Note: RPSL object texts in this example are shortened because of
formatting.

The following validation rules MUST be observed when creating or
parsing Delta Files:

* The nrtm_version MUST be 4.
* The type MUST be "delta".
* The source MUST be a valid RPSL name, matching the Update Notification File.
* The session_id MUST be a random v4 UUID unique to this session
  for this source, matching the Update Notification File.
* The version MUST be an unsigned positive integer, matching the
  Update Notification File entry for this delta.
* The changes attribute MUST be an array of one or more elements, each having:
  - An action attribute, which is either "delete" for object deletions,
    or "add_modify" for additions or modifications.
  - If action is "delete": an existing_object attribute with the RPSL text of
    the last version of the object prior to deletion.
  - If action is "add_modify": a new_object attribute with the RPSL text of
    the new version of the object.
* The source attribute in the RPSL object texts MUST match the source attribute
  of the Delta File.
* The file MUST be UTF-8 encoded.


## Operational Considerations

### RPSL Object Validation

Throughout the years, various implementations of IRR servers have taken
liberties with the various RFCs regarding RPSL. Implementations have
introduced different new object classes, attributes and validation rules.
Current IRR Databases also contain legacy objects which were created under
different validation rules. In practice, there is no uniformly implemented
standard for RPSL, but merely rough outlines partially documented in
different places.

This has the potential to create interoperability issues. Some are addressed
by NRTMv4, like having a consistent character set when mirroring data between
implementations. However, some issues can not be addressed in this way, such as
one implementation introducing a new object class that is entirely unknown to
another implementation.

A mirror client SHOULD be able to process unknown object classes and objects
that are invalid according to its own validation rules, without rejecting
remaining objects or preventing future updates.

It is RECOMMENDED for mirror clients to log these cases,
particularly those where an object was discarded due to violating validation
rules. These cases create an inconsistency between the IRR objects of the server
and client, and logs facilitate later analysis.

It is RECOMMENDED for mirror clients to be flexible where possible and
reasonable when applying their own validation rules to RPSL objects retrieved
from mirror servers.
For example, a route object with an origin attribute that is not a valid AS
number can't be salvaged. There is no way for an IRR server to correctly
parse and index such an object. However, a route-set object
whose name does not start with "RS-" (TODO RFC REF), or an inetnum with an
unknown "org" attribute, still allows the mirror client to interpret it
unambiguously even if it does not meet the mirror client's own validation
rules for authoritative records.

### Intermediate mirror instances

An IRR Database generally has a single authoritative source. In some cases,
an instance run by a third party will function as a kind of intermediate:
both being a mirror client, mirroring IRR objects from the authoritative source,
and simultaneously function as a mirror server to yet another mirror client.

There are various operational reasons for such a setup, such as the intermediate
filtering certain records. Regardless of the reason, the mirror client and
server function of an IRR server must be treated as separate processes.
In particular, this means they MUST have separate session IDs. The intermediate
server MUST NOT republish the same files it retrieved from the authoritative
source with the same session ID.

### HTTPS Considerations

TODO


## Security Considerations

IRR objects serve many purposes, including
automated network configuration and filtering. Manipulation of IRR objects
can therefore have a significant security impact. However, security in existing
protocols is mostly absent.

Currently, the most common protocols for IRR Database mirroring are FTP for
retrieving full snapshots, and NRTM version 3 for retrieving later changes.
There are no provisions for integrity or authenticity, and there are various
scenarios where mirroring may not be reliable.

NRTMv4 requires integrity verification. The Delta and Snapshot Files are
verified using the SHA-256 hash in the Update Notification File, and the
Update Notification File is verified using its signature file.
Additionally, the channel security
offered by HTTPS further limits security risks.

By allowing publication on any HTTPS endpoint, NRTMv4 allows for extensive
scaling, and there are many existing techniques and services to protect against
denial-of-service attacks.
In contrast, NRTMv3 required mirror clients to directly query the IRR server
instance with special whois queries. This scales poorly, and there are no
standard protections against denial-of-service available.