# Background

These are notes regarding NRTMv4 that are useful background, but not
really part of the speficication.

## Implementation

The main IRR servers now are RIPE whois, IRRDv4 and legacy IRRd.
Legacy IRRd will almost certainly not be updated. For RIPE whois,
it is unclear which versions are still running where and whether
they can be updated.

However, adoption of NRTMv4 can be gradual: supported servers
can offer NRTMv4 and NRTMv3 as both client and server. IRRDv4
instances will also be able to receive updates through one
protocol and publish them in the other.

IRRDv4 does a few unusual things that interact with NRTMv3:

* **Synthetic NRTM**: admins can periodically load a full snapshot of
  a source in IRRd. IRRd internally generates a diff to the current
  data, and generates NRTM changes for the difference. Therefore, translating
  periodic snapshots to a source that can be mirrored over NRTM.
  This design for NRTMv4 would be fully compatible.
* **Synchronised serials**: some deployments use one IRRd instance to
  process authoritative changes, then mirror to a group of servers, and load
  balance client queries over them. This means each mirror needs to have
  the same changes under the same serials, called
  [synchronised serials](https://irrd.readthedocs.io/en/latest/users/mirroring/#serial-handling)
  in IRRd, only available in certain scenarios.
  In NRTMv4, the authoritative server can
  produce the required files, push them to any HTTP host, and not have to
  deal with any of the load. Therefore, this setup will actually become much
  easier with NRTMv4.
* **RPKI and scope filter**: IRRd can
  [validate route(6) objects](https://irrd.readthedocs.io/en/latest/admins/rpki/)
  against RPKI status or scope filter. Invalid objects become invisible to
  clients. If they later change status to not_found/valid they become visible
  again. This is reproduced to any mirrors by inserting NRTM ADD/DEL's for
  these changes - regardless of whether that instance is authoritative for
  that source. For NRTMv4, the same could be done. IRRd could include the
  reason for ADD/DEL.
  (As a sidenote, queries reveal whether an object is RPKI not found or valid,
  but changes between these states do not cause a visibility change therefore
  do not cause an NRTM update.)

The legacy `!j` query should probably be left as is. `!J` can be updated
to include NRTMv4 mirroring information.

Other important implementation detail: generation of new notification files
may need locking so that they always include latest delta and snapshot info,
which might be generated at the same time.

## Other options considered

One other option was considered: to push the changes over websockets.
This has wide client support, and reduces latency to almost zero. However:

* websockets are not designed for the large initial snapshot retrieval
* it does not scale as well: although some initial testing showed that even
  light servers could handle considerable numbers of clients, the decoupling
  that publishing over HTTP provides is a big upside.
* it is a much less known format, and therefore would increase the barrier
  for implementation, compared to "plain" HTTP downloads


## Why

NRTMv3 has a number of issues, and most of those should be addressed in v4:

Definitely:

* There are no integrity or authenticity checks at any level.
* NRTMv3 has an undesirable attachment to the plain port 43 whois protocol.
* However, full files need to be retrieved from a totally unrelated other
  location. Neither refers to the other. With yet another file containing
  the essential serial number of the snapshot.
* There's not really any single standard at all or documentation for
  NRTM queries or the IRR data dumps.
* There is no consistent way to distinguish "I have no new data" from
  "your update query failed".
* Each NRTMv3 query, whether or not there are updates, places load directly
  on the whois server that is also serving user queries with performance
  constraints.
* There's no decent way to scale NRTMv3.
* Versioning in NRTMv3 is done through a single serial number which
  is often non-sequential.
* There is no way to determine whether a set of changes apply coherently
  to a particular local copy. If people switch NRTM sources for the
  same URL, data inconsistencies may happen.
* There is no way for a source to say "reimport everything and continue
  NRTM after that".
* There is no standard on character set or any way to signal it, causing
  encoding problems.

Maybe:

* There is no way to include any kind of metadata with a change.
  Some places try by inserting weird attributes.
* Adding a new object and updating an existing object are indistinguishable.
  IRRd doesn't actually care at this point, and might not always know
  when generating the journal.

Probably not included:

* There is no way to signal errors, like "you sent me an object that in
  my opinion has syntax errors". Difficult as there is no single opinion
  on RPSL syntax and there are legacy objects.

NRTMv1 is like v3 but even worse. v2 doesn't seem to exist.
