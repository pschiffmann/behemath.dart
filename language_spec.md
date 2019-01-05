mathlite syntax specification
=============================

fragments
---------

blocks
------

binding precendence
-------------------

Sometimes multiple binding candidates exist for a fragment.
For example, in the expression
```
 n
 ∏
i=1
```
the mathlite parser has to decide whether it should first connect `n`, `∏` and `=` into a column, or `i`, `=` and `1` into a row.

First of all, fragments from different bracket scopes never form a binding.
All elements that appear inside a bracket pair, and the brackets themselves, are assembled into a single fragment first, before any of the other rules apply.

After that, decisions are resolved by the following precedence list.

 1. Group horizontally aligned fragments with a distance of 1 into a `Row`.
 2. If an `operator` token is vertically aligned with a single fragment above and/or below itself with distance 1, and those fragments have a distance of >=2 to all of their other neighbours, group them into an `UnderOverScript`.
 3. Group horizontally aligned fragments with a distance of 2 into a `Row`.
 4. Group fragments with horizontal distancy of >=2, vertical distance of >=1 into tables.
