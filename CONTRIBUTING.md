Contributing to Busted
======================

So you want to contribute to busted? Fantastic! Here's a brief overview on
how best to do so.

## What to change

Here's some examples of things you might want to make a pull request for:

* New language translations
* New features
* Bugfixes
* Inefficient blocks of code

If you have a more deeply-rooted problem with how the program is built or some
of the stylistic decisions made in the code, it's best to
[create an issue](https://github.com/Olivine-Labs/busted/issues) before putting
the effort into a pull request. The same goes for new features - it might be
best to check the project's direction, existing pull requests, and currently open
and closed issues first.

## Style

* Two spaces, not tabs
* Variables have_underscores, classes are Uppercase
* Wrap everything in `local`, expose blocks of code using the module pattern

Look at existing code to get a good feel for the patterns we use.

## Using Git appropriately

1. [Fork the repository](https://github.com/Olivine-Labs/busted/fork_select) to
your Github account.
2. Create a *topical branch* - a branch whose name is succint but explains what
you're doing, such as "klingon-translations"
3. Make your changes, committing at logical breaks.
4. Push your branch to your personal account
5. [Create a pull request](https://help.github.com/articles/using-pull-requests)
6. Watch for comments or acceptance

Please note - if you want to change multiple things that don't depend on each
other, make sure you check the master branch back out before making more
changes - that way we can take in each change seperately.
