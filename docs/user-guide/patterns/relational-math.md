# Relational Properties for Nonlinear Math

Contracts that compute with ratios &mdash; share prices, interest indexes,
fixed-point multiplication like `mulDiv(x, y, d)` &mdash; confront the Prover
with {term}`nonlinear arithmetic`, which is the hardest theory for SMT
solvers and a frequent cause of timeouts (see
{ref}`high-nonlinear-op-count`).  Two habits keep such specifications both
tractable and meaningful: state *relational* properties instead of mirroring
the exact formula, and summarize the nonlinear primitives with axiomatized
abstractions.

## Prefer relational properties over formula mirroring

A rule that recomputes the contract's exact formula in CVL, e.g.

```cvl
assert shares == assets * totalShares() / totalAssets();  // anti-pattern
```

has two problems: it duplicates the implementation (so an implementation bug
is faithfully reproduced in the spec and never caught), and it forces the
solver through the same nonlinear reasoning twice.  Relational properties
avoid both, and usually capture what users actually rely on:

 - **Monotonicity** &mdash; more in, more out (or at least not less):

   ```cvl
   rule convertToSharesMonotone(uint256 a1, uint256 a2) {
       require a1 <= a2;
       assert convertToShares(a1) <= convertToShares(a2);
   }
   ```

 - **Bounds** &mdash; the result never exceeds a simple linear envelope, e.g.
   `shares <= assets` when the share price is at least one.

 - **Round-trip inequalities** &mdash; converting back and forth never
   creates value:

   ```cvl
   rule roundTripFavorsProtocol(uint256 assets) {
       assert convertToAssets(convertToShares(assets)) <= assets;
   }
   ```

 - **Additivity up to rounding** &mdash; splitting an operation loses at most
   one unit per split (see
   {doc}`multi-call properties <multicall>`).

Each of these detects real rounding-direction and accounting bugs, and none
of them requires the solver to reason about the exact product `x * y`.

## Summarizing nonlinear primitives with axiomatized abstractions

When rules still time out because the contract itself calls a nonlinear
helper many times, summarize the helper with a CVL function that constrains
the result *relationally* instead of computing it.  The following abstraction
of floor division `x * y / d` states exactly the floor property and nothing
else:

```cvl
methods {
    // replace the contract's mulDivDown with a relational abstraction
    function MathLib.mulDivDown(uint256 x, uint256 y, uint256 d) internal returns (uint256)
        => mulDivDownAbstract(x, y, d);
}

function mulDivDownAbstract(uint256 x, uint256 y, uint256 d) returns uint256 {
    require d != 0, "mulDiv reverts on division by zero";
    uint256 res;
    mathint xy = x * y;

    // res is the floor of x*y/d, characterized by:
    //   res * d <= x * y < (res + 1) * d
    require res * d <= xy;
    require xy < (res + 1) * d;
    return res;
}
```

The solver never multiplies two unknowns from the contract's data path; it
only checks the two axioms, which is dramatically cheaper.  Useful facts such
as `mulDivDown(x, y, d) <= mulDivDown(x', y, d)` for `x <= x'` follow from
the axioms automatically.

The same recipe extends to rounding-up variants: axiomatize
`mulDivUp` by `res * d >= x * y` and `x * y > (res - 1) * d`, which also
yields the cross-variant fact that the two results differ by at most one.

```{warning}
Axioms expressed as `require` statements are *assumed*, not checked.  Two
pitfalls follow:

 - **Unsatisfiable axioms make every rule vacuous.**  If no `res` can satisfy
   the constraints, rules pass trivially.  The floor characterization above
   is satisfiable whenever the true quotient fits in `uint256`; when
   `x * y / d` exceeds `max_uint256` no such `res` exists, so those paths
   are silently pruned &mdash; much as the real `mulDivDown` reverts on
   overflow, but without any visible signal.  This is exactly the corner
   where coverage disappears, so always confirm with the
   {doc}`sanity checks </docs/prover/checking/sanity>` after introducing an
   abstraction (see also {doc}`vacuity <vacuity>`).
 - **Weak axioms lose precision, not soundness.**  The abstraction above
   allows every behavior the real `mulDivDown` has (plus none it does not),
   so verified rules remain sound.  But a property that depends on a fact
   *not implied by the axioms* will produce a spurious counterexample; in
   that case strengthen the axioms rather than the rule's `require`s.
```
