Tutorial and Workshops
======================

(tutorial)=
Tutorial
--------

The Certora Tutorial is a series of guided lessons that covers installation and
basic usage of the Certora Prover.

It is available [on github][tutorial].

The Tutorial is organized as a series of lessons and exercises.  You are
encouraged to clone the git repository and work through the exercises yourself.
Each directory has a `README` file that explains the lesson.

[tutorial]: https://github.com/Certora/Tutorials/blob/master/README.md

Stanford DeFi Security Summit
-----------------------------

```{todo}
The links are to the playlists instead of the timestamps
```

[The Stanford DeFi Security Summit, August 2022][stanford] is a recorded 2-day workshop that
covers basic Prover usage with several hands-on examples.  It covers the
following topics:

| Video | Slides | Notes |
| ----- | ------ | ----- |
| [Overview                   ](https://www.youtube.com/playlist?list=PLKtu7wuOMP9Wp_O8kylKbtFYgM8HVTGIA) | ({download}`slides <basics/stanford/01-intro.pdf>`)           | |
| [Installation and setup     ](https://www.youtube.com/playlist?list=PLKtu7wuOMP9Wp_O8kylKbtFYgM8HVTGIA) | ({download}`slides <basics/stanford/02-setup.pdf>`)           | |
| [Writing basic rules        ](https://www.youtube.com/playlist?list=PLKtu7wuOMP9Wp_O8kylKbtFYgM8HVTGIA) | ({download}`slides <basics/stanford/03-rules.pdf>`)           | |
| [Writing parametric rules   ](https://www.youtube.com/playlist?list=PLKtu7wuOMP9Wp_O8kylKbtFYgM8HVTGIA) | ({download}`slides <basics/stanford/04-parametric.pdf>`)      | |
| [Invariants                 ](https://www.youtube.com/playlist?list=PLKtu7wuOMP9Wp_O8kylKbtFYgM8HVTGIA) | ({download}`slides <basics/stanford/05-invariants.pdf>`)      | |
| [Ghosts and hooks           ](https://www.youtube.com/playlist?list=PLKtu7wuOMP9Wp_O8kylKbtFYgM8HVTGIA) | ({download}`slides <basics/stanford/06-ghosts.pdf>`)          | |
| [Hyperproperties            ](https://www.youtube.com/playlist?list=PLKtu7wuOMP9Wp_O8kylKbtFYgM8HVTGIA) | ({download}`slides <basics/stanford/07-hyperproperties.pdf>`) | |
| [Designing specifications   ](https://www.youtube.com/playlist?list=PLKtu7wuOMP9Wp_O8kylKbtFYgM8HVTGIA) | ({download}`slides <basics/stanford/08-design.pdf>`)          | |
| [The Certora Prover pipeline](https://www.youtube.com/playlist?list=PLKtu7wuOMP9Wp_O8kylKbtFYgM8HVTGIA) | ({download}`slides <basics/stanford/09-pipeline.pdf>`)        | |
| [SMT solvers                ](https://www.youtube.com/playlist?list=PLKtu7wuOMP9Wp_O8kylKbtFYgM8HVTGIA) | ({download}`slides <basics/stanford/10-smt.pdf>`)             | Guest: Clark Barrett, Stanford |

The covered examples are available on [github][examples].

[stanford]: https://www.youtube.com/playlist?list=PLKtu7wuOMP9Wp_O8kylKbtFYgM8HVTGIA
[examples]: https://github.com/Certora/Examples

EthCC Paris
-----------

[EthCC Paris, July 2022][ethcc] is an earlier 3-day workshop in a similar
style that covers the same material and a few additional topics:

| Video | Slides | Notes |
| ----- | ------ | ----- |
| [Overview                    ](https://www.youtube.com/watch?v=sdEfc-58CUE&list=PLKtu7wuOMP9XHbjAevkw2nL29YMubqEFj&index=1&t=1s)     |  | |
| [Installation and setup      ](https://www.youtube.com/watch?v=CwCX0TuDfTE&list=PLKtu7wuOMP9XHbjAevkw2nL29YMubqEFj&index=2&t=2s)     |  | |
| [Writing basic rules         ](https://www.youtube.com/watch?v=66Gjzgl87L8&list=PLKtu7wuOMP9XHbjAevkw2nL29YMubqEFj&index=3&t=21s)    |  | |
| [Writing parametric rules    ](https://www.youtube.com/watch?v=gMjELxgMY30&list=PLKtu7wuOMP9XHbjAevkw2nL29YMubqEFj&index=4&t=534s)   |  | |
| [Invariants                  ](https://www.youtube.com/watch?v=VqboepMVbg4&list=PLKtu7wuOMP9XHbjAevkw2nL29YMubqEFj&index=5&t=2s)     |  | |
| [Multicontract verification  ](https://www.youtube.com/watch?v=WR8eAQZzd8Y&list=PLKtu7wuOMP9XHbjAevkw2nL29YMubqEFj&index=6)          |  | Not covered in Stanford workshop |
| [The Certora Prover pipeline ](https://www.youtube.com/watch?v=jAiBUebBs88&list=PLKtu7wuOMP9XHbjAevkw2nL29YMubqEFj&index=7)          |  | |
| [Designing specifications    ](https://www.youtube.com/watch?v=f3K-68k7vig&list=PLKtu7wuOMP9XHbjAevkw2nL29YMubqEFj&index=8)          |  | |
| [Liquidity pool example      ](https://www.youtube.com/watch?v=GLGXQSaE5b4&list=PLKtu7wuOMP9XHbjAevkw2nL29YMubqEFj&index=9)          |  | Not covered in Stanford workshop |
| [Checking the spec           ](https://www.youtube.com/watch?v=csTe6ub3Jwg&list=PLKtu7wuOMP9XHbjAevkw2nL29YMubqEFj&index=10)         |  | Not covered in Stanford workshop |
| [Ghosts and hooks            ](https://www.youtube.com/watch?v=NQ1ZQnlYFOQ&list=PLKtu7wuOMP9XHbjAevkw2nL29YMubqEFj&index=11)         |  | |

The last day of the workshop was devoted to an extended exercise verifying the
version 3 of the Aave Token:

| Video | Slides | Notes |
| ----- | ------ | ----- |
| [Aave token overview         ](https://www.youtube.com/watch?v=BGdHsvQMmy8&list=PLKtu7wuOMP9XHbjAevkw2nL29YMubqEFj&index=12&t=1618s) |  | |
| [Aave token properties       ](https://www.youtube.com/watch?v=_YW-uReng44&list=PLKtu7wuOMP9XHbjAevkw2nL29YMubqEFj&index=13&t=25s)   |  | |
| [Aave token setup            ](https://www.youtube.com/watch?v=Epe90JSmNqc&list=PLKtu7wuOMP9XHbjAevkw2nL29YMubqEFj&index=14)         |  | |
| [Aave token exercise         ](https://www.youtube.com/watch?v=IPasjUOFUdA&list=PLKtu7wuOMP9XHbjAevkw2nL29YMubqEFj&index=15)         |  | |

[ethcc]:       https://www.youtube.com/playlist?list=PLKtu7wuOMP9XHbjAevkw2nL29YMubqEFj

Aave Community Day
------------------

[Aave Community Day, April 2022][aave] is a condensed 3-hour workshop with
fewer exercises.

[aave]: https://www.youtube.com/playlist?list=PLKtu7wuOMP9WOLJNPafbrd0lehfc7yxso

