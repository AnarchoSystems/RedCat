# RedCat

A red cat is not [an ox](https://en.wikipedia.org/wiki/Redox#Mnemonics)!

RedCat is a new Redux-inspired unidirectional data flow framework with an emphasis on static knowledge. RedCat provides a couple of useful Reducer protocols based on generic functions to maybe enable more optimization by the compiler. There are also a handful of concrete Reducer types that enable you to create Reducers with anonymous functions as usual. Maybe the coolest feature: in order to compose two Reducers, only their State type needs to agree!

There is also a proof of concept:
- [RedCatTicTacToe](https://github.com/AnarchoSystems/RedCatTicTacToe): a Tic-Tac-Toe implementation using RedCat.
