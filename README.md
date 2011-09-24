GridView component for iOS
===


This project is not yet feature complete (e.g. the implementation for section headers and footers is still missing) and inserts and updates aren't yet possible without a complete `reload`.

These additions should not take too long to code and if you've got something to contribute, you're more then welcome to.

However this implementation currently by far has the _best scrolling performance_ compared to similar projects – at least that I'm aware of.

Even on my 3G – yeah retro I know ^^ – it's blazingly fast.


Requirements
---

This GridView does not rely on ARC ([Automatic Reference Counting](http://clang.llvm.org/docs/AutomaticReferenceCounting.html)) or other Xcode 4.2 features, so it should be instantly usable in any of your apps that you want to submit.

Though I have not tested that, it should work on iOS versions < 4.0.
