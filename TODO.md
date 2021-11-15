# TODO

* ~~If we only publish snapshots and deltas when data changes, i.e. nothing
  happens if there is no change, how do people distinguish a stale publication
  point from a server that has had no changes? Some IRRs are very quiet.
  Maybe the Update Notification File should have a generation timestamp and
  be required to refresh (and re-sign) daily or so, even if there are no
  other changes?~~ -> https://github.com/mxsasha/nrtmv4/issues/5
* ~~Mirror server / mirror client may not be the most optimal names, but the
  best I have so far.~~ -> https://github.com/mxsasha/nrtmv4/issues/4
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
  of plaintext or gzipped content? If widely supported, recommending gzip
  compression at the HTTP server level seems easiest.
* When generating the first snapshot, it would have version 1, with no delta for
  version 1. This is inconsistent with later snapshots, where the snapshot version
  matches the version of a delta. Maybe this is not an issue because when "updating"
  to version 1, a client always needs the snapshot anyways, and then resumes with
  delta version 2, etc.
* ~~IRR tends to have relatively frequent but small changes. Delta expiry (when
  combined deltas are larger than the snapshot) will therefore be very rare.
  This can cause clients to need to download thousands of delta files,
  which may be less data transfer than reloading from snapshot, but are still
  slow due to the number. Either delta expiry, forcing snapshot reload, needs to
  happen earlier or, more ideal, we need a mechanism for servers to aggregate old
  delta files. This would require the Update Notification File to refer to a file
  that contains a range of versions, retrievable with a single HTTP request.
  The individual versions should still be split in that file, so that clients at
  intermediate versions can correctly update. Sasha has ideas on the details here.~~ -> https://github.com/mxsasha/nrtmv4/issues/3
* We need good key management. Do we recommend/require periodic rollovers? How often?
  What is the process? How is this communicated to users? Perhaps keys can be stored
  with IANA same as certificate transparency which would solve a lot of issues.
  Job is exploring this more.
* Perhaps we need an in-band signalling mechanism to admins. Key rotation could
  be a case, but also maybe a change of URL. Question: how would IRRd communicate
  this to the admins effectively?
* Work out more details for the HTTPS section.
* Write a proper JSON schema? https://json-schema.org/
* Ed25519 is a good choice by all indications, but that may need more
  explanation - not in the specification itself probably though.
* Should there be something in here about loading from local files instead
  of HTTPS? Not too common, but there are some people who will want to do
  that. Should probably be allowed.
* ~~We now consistently use the term "RPSL objects" - in earlier versions this
  was a mix of "IRR objects" and "RPSL objects". Good wording?~~ -> https://github.com/mxsasha/nrtmv4/issues/4
* Should we encode the RPSL object text as base64? Makes it bigger, but
  reduces encoding issues, as the XML can now fit in ASCII.
* Are the sample URLs in the example update notification file good choices?
  Probably implementations will follow those closely.
