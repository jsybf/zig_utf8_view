# dependency
written in zig 0.13.0 (i think it will run in previous version).

# what is this
read input from stdin then output table of `character`, `unicode decimal`, `unicode hex`,`utf-8 binary`.

implemented
- decode UTF-8
- clean cli table view

written in purpose of learning zig by writting something useful.


# how to run
```bash
zig build-exe utf8_view.zig
echo "<INPUT_STRING>" | ./utf8_view.zig
```

expected result is like below.
```
┌─────────┬────────────────┬────────────┬───────────────────────────────────┐
│character│unicode(decimal)│unicode(hex)│utf-8(binary)                      │
├─────────┼────────────────┼────────────┼───────────────────────────────────┤
│a        │97              │U+00061     │01100001                           │
├─────────┼────────────────┼────────────┼───────────────────────────────────┤
│b        │98              │U+00062     │01100010                           │
├─────────┼────────────────┼────────────┼───────────────────────────────────┤
│c        │99              │U+00063     │01100011                           │
├─────────┼────────────────┼────────────┼───────────────────────────────────┤
│🙎        │128590          │U+1F64E     │11110000 10011111 10011001 10001110│
└─────────┴────────────────┴────────────┴───────────────────────────────────┘
```
