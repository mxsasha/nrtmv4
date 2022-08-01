This repo is for ideas and work for the NRTM v4 protocol and implementations.

See [draft-ietf-grow-nrtm-v4.html](https://htmlpreview.github.io/?https://github.com/mxsasha/nrtmv4/blob/main/draft-ietf-grow-nrtm-v4.html) for
the protocol design, [TODO.md](TODO.md) for
open TODOs, and [background.md](background.md) for some more background and
implementation notes.

Do check that the XML version is not newer than the HTML version. The XML version
is authoritative.

Authoring Conventions
---------------------

The four golden rules:

* One sentence per line, this makes XML diff reading easier.
* Only edit the .xml file (the .txt and .html files are computer generated).
* Be sure to keep track of the names of contributors through the Acknowledgements section and the git log.
* Before committing, generate a new txt/html by running `make`. Also will help you catch syntax errors.

Note Well
------

This repository relates to activities in the Internet Engineering Task Force
(IETF). All material in this repository is considered Contributions to the IETF
Standards Process, as defined in the intellectual property policies of IETF
currently designated as BCP 78 (https://www.rfc-editor.org/info/bcp78), BCP 79
(https://www.rfc-editor.org/info/bcp79) and the IETF Trust Legal Provisions
(TLP) Relating to IETF Documents (http://trustee.ietf.org/trust-legal-provisions.html).

Any edit, commit, pull request, issue, comment or other change made to this
repository constitutes Contributions to the IETF Standards Process
(https://www.ietf.org/).

You agree to comply with all applicable IETF policies and procedures,
including, BCP 78, 79, the TLP, and the TLP rules regarding code components
(e.g. being subject to a Simplified BSD License) in Contributions.
