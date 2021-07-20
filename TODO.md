# TODO

* If we only publish snapshots and deltas when data changes, i.e. nothing
  happens if there is no change, how do people distinguish a stale publication
  point from a server that has had no changes? Some IRRs are very quiet.
  Maybe the Update Notification File should have a generation timestamp and
  be required to refresh (and re-sign) daily or so, even if there are no
  other changes?
* Mirror server / mirror client may not be the most optimal names, but the
  best I have so far.
* In the delta and/or files, we could add space for metadata. What kind of
  data is useful there? IRRd has, for each individual object change, the reason
  for the change and a unique serial, which might help in tracing.
  This might depend on individual implementations.
* RPKI and the scope filter currently make objects entirely invisible, i.e. when
  an object becomes invalid or out of scope, an NRTM DELETE is generated. Is this
  desirable? It's the only way in NRTMv3, but we could supporting something like
  "not a real deletion but more of an administrative suspension" in NRTMv4.
  One notable use: when doing high availability setups based on NRTM, after
  a failover, RPKI invalid objects are entirely lost, i.e. they do not return if
  their RPKI status changes to be (valid,not_found) later. If there is no
  failover, the objects are restored if the RPKI status changes. This does not
  feel nice.
* Recommending GZIP seems useful especially for snapshots. RPSL compresses well.
  Should this be done by the HTTP server? Served as gzipped files? Hash/signature
  of plaintext or gzipped content?
* Work out more details for the HTTPS section.
* Add proper references (e.g. to RFC 2622 section 2 for "valid RPSL name")
* Write a proper JSON schema? https://json-schema.org/
* Ed25519 is a good choice by all indications, but that may need more
  explanation - not in the specification itself probably though.
* Should there be something in here about loading from local files instead
  of HTTPS? Not too common, but there are some people who will want to do
  that. Should probably be allowed.
