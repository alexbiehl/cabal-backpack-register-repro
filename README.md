# How to reproduce

Run

1. `$ cabal configure --ghc-option=-j1`

  -j1 is needed as GHC doesn't support parallel typechecking with Backpack yet.

2. `$ cabal build`

3. `$ cabal copy`

4. `$ cabal register`

    Step 4 should fail with an error similar to the following

```
cabal:
'/nix/store/m338klajhqlw7v4jd61fiqd82wx305fj-ghc-8.4.3-with-packages/bin/ghc'
exited with an error:
Failed to load interface for ‘Stuff’
no unit id matching ‘backpack-trans-0.1.0.0-L6CFTQZAAWWFpCQD2NXR4W-indef’ was
found
```

turning on verbosity shows the command

```
/nix/store/m338klajhqlw7v4jd61fiqd82wx305fj-ghc-8.4.3-with-packages/bin/ghc --abi-hash -fbuilding-cabal-package -O -outputdir dist/build -odir dist/build -hidir dist/build -stubdir dist/build -i -idist/build -isrc -idist/build/autogen -idist/build/global-autogen -Idist/build/autogen -Idist/build/global-autogen -Idist/build -optP-include -optPdist/build/autogen/cabal_macros.h -this-unit-id backpack-trans-0.1.0.0-L6CFTQZAAWWFpCQD2NXR4W -this-component-id backpack-trans-0.1.0.0-L6CFTQZAAWWFpCQD2NXR4W -instantiated-with 'Sig=<Sig>' -fno-code -fwrite-interface -hide-all-packages -Wmissing-home-modules -no-user-package-db -XHaskell2010 Lib -j1
```

is at fault here. Obviously GHC tries to load the `Stuff` interface when trying to calculate the abi hash. And for some reason it doesn't find it. Following the comments
on the Cabal issue tracker I read that ghc --abi-hash shouldn't need a package database as it wouldn't suck in interface files besides the ones explicitly given on the
command line. That is obviously not the case here.

Now, if you look at the `Stuff` module you will find that the data type declaration `X` has a `deriving (Generic)` clause.
If you comment that line out, repeat step 2., 3. and 4. it will work without an error.

The Generic class has an associated data family which constitutes to the `family instance modules` in the interface file
for `Lib`:

```
family instance modules: Stuff Control.Applicative
                         Data.Functor.Const Data.Functor.Identity Data.Monoid
                         Data.Semigroup.Internal GHC.Generics GHC.IO.Exception
```

Commenting out the Generic deriving removes the `Stuff` entry from the fam instance modules.

In addition, `Lib` is also referring to `Stuff` by using `Stuff.test` function in `doOtherStuff`. This
doesn't seem to cause any errors once the deriving clause has been commented out.


I suspect there is something fishy somehwere around modules with family instances here,
maybe the consistency check happens too early and loads interfaces although it shouldn't?

## Update

while I have no idea if the assumption, that GHC doesn't load dependencies (why else would it work to
invoke --abi-hash withour package db, right?). Maybe we just need to be able to load the other sublibraries
interface files?

## Update 2

Maybe it is not as drastic as it all seems. I realized that we can influence the search path for
interfaces via the -i flag. I see we are passing `-i dist/build` already. Why not also
pass `-i dist/build/indef`?
