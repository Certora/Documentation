Events
======

```{todo}
The events block is currently unused and undocumented.
```

```{versionchanged} 2.0
Events have been removed.
```
Syntax
------

The syntax for the events block is given by the following [EBNF grammar](syntax):

```
events ::= "events" "{" { event } "}"
event  ::= id "(" event_params ")"

event_param ::= type [ "indexed" ] id
```

See {doc}`types` for the `type` production, and {ref}`identifiers` for the `id`
production.

