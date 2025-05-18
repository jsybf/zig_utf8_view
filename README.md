# dependency
written in zig 0.13.0 (i think it will run in previous version).

# what is this
read input from stdin then output table of `character`, `utf-8 binary`, `unicode hex`.

implemented
- decode UTF-8
- clean cli table view

written in purpose of learning zig by writting something useful.


# how to run
```bash
echo "<INPUT_STRING>" | zig run utf_8_view.zig
```

expected result is like below.
```
┌────┬───────────────────────────────────┬────────────┐
│char│utf-8(binary)                      │unicode(hex)│
├────┼───────────────────────────────────┼────────────┤
│a   │01100001                           │U+00061     │
├────┼───────────────────────────────────┼────────────┤
│b   │01100010                           │U+00062     │
├────┼───────────────────────────────────┼────────────┤
│c   │01100011                           │U+00063     │
├────┼───────────────────────────────────┼────────────┤
│🙎   │11110000 10011111 10011001 10001110│U+1F64E     │
└────┴───────────────────────────────────┴────────────┘
```
