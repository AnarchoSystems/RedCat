# RedCat

What is RedCat?

A red cat is not [an ox](https://en.wikipedia.org/wiki/Redox#Mnemonics)!

RedCat is a unidirectional data flow framework with an emphasis on ergonomics. RedCat provides a couple of useful Reducer protocols that make composition of reducers quite readable. There are also a handful of concrete Reducer types that enable you to create Reducers with closures like in other such frameworks.

## Examples

### Reducers 

The core component of every unidirectional data flow framework is the reducer. Here is one:

```swift
let incDecReducer = Reducer {(action: IncDec, state: inout Int in
   switch action {
      case .inc:
         state += 1
      case .dec:
         state -= 1
   }
}
```

The type of the above example will be inferred to ```Reducer<ClosureReducer<Int, IncDec>>```. This is because in RedCat, reducers aren't just wrappers or type aliases for a certain type of closure, they are their own thing. Here's a more verbose way to achieve something similar to the above:

```swift
struct IncDecReducer : ReducerProtocol {
 
   func apply(_ action: IncDec, to state: inout State) {
      switch action {
         case .inc:
            state += 1
         case .dec:
            state += 1
      }
   }

}

let incDecReducer = IncDecReducer()

```

While more verbose, this may come in handy when dealing with more complex scenarios. Sometimes, an action cannot meaningfully be decomposed into subactions and the reducer function becomes lengthy. In this case, you want to factor code out into other meaningfully named functions. If reducers are defined by anonymous functions, it is not quite clear where to put those helpers. If they are self-contained structs, the helpers can just be private methods of the reducer.

### Composing Reducers

Composing reducers is quite simple:

```swift
let reducer = myReducer1
                  .compose(with: myReducer2)
                  .compose(with: myReducer3)
```

The only prerequisite is that their state and action types agree.

Since currently there are no wrappers that support changing the action type, we recommend the more verbose spelling:

```swift

struct Dispatcher : DispatchReducer {

   @ReducerBuilder
   func dispatch(_ action: HighLevelAction) -> VoidReducer<MyConcreteRootState> {
         switch action {
             case .module1(let module1Action):
                 Module1Reducer().bind(to: \.module1).send(module1Action)
             case .module2(let module2Action):
                 Module2Reducer().bind(to: \.module2).send(module2Action)
                 .compose(with: someVoidReducerReactingToModule2Actions)
                 .asVoidReducer()
                 ...
         }
   }

}

```

Note that this is also a bit more efficient than the usual composition of reducers with different action types, since the usual composition would destructure the action using ```if case``` (which is dynamic), while an exhaustive ```switch``` over an enum can be [optimized](https://forums.swift.org/t/complexity-of-enum-switching/49440/2). Also, it is safer, since you cannot accidentally miss a case.

### Modularization

Of course, the main goal is to write reducers only for components of the state and then aggregate them into a reducer for the whole state. In order to make this easy, there are a couple of helpers.

For instance, you can bind a reducer to a certain mutable property of your state: 

```swift
struct Foo {
   
   var bar : Int
   
   static let reducer = DetailReducer(\Foo.bar) {
      incDecReducer
   }
   
}
```

Or you can bind it to the associated value of an enum case

```swift
import CasePaths

enum MyEnum : Emptyable {

   case empty
   case bar(Int)
   
   static let reducer = AspectReducer(/MyEnum.bar){
      incDecReducer
   }
   
}
```

Here, we used a [CasePath](https://github.com/pointfreeco/swift-case-paths). Additionally, the enum has to conform to ```Emptyable``` or ```Releasable``` (parent protocol of ```Emptyable```) to minimize the risk of triggering a [copy-on-write](https://medium.com/@lucianoalmeida1/understanding-swift-copy-on-write-mechanisms-52ac31d68f2f).

Additionally, there's a way to bind the reducers implicitly to properties or cases while composing:

```swift
let structReducer = reducer1.compose(with: reducer2, property: \.foo)
let enumReducer = reducer3.compose(with: property3, aspect: /EnumType.bar)
```

### Naming Schemes

Plain reducers, aspect reducers and detail reducers come in two flavors:

```swift
XXXReducerProtocol // protocol requires "apply" method
XXXReducerWrapper // protocol requires another reducer as "body"
```

and a struct ```XXXReducer```. The plain ```Reducer``` can be initialized using a closure or using a keypath/casepath and a wrapped reducer. This makes ```Aspect/Detail``` in ```Aspect/DetailReducer``` optional, as the ```Reducer``` will then just wrap itself around the appropriate type.

For discoverability, we recommend adding reducer types, "namespaced" by their ```State```type, as nested types to ```Reducers```, a public "namespace" provided by RedCat.

### The Store 

If you're done composing the reducer, you may wonder how to make it do something useful. Unidirectional data flow frameworks are opinionated about this: There should only be one "global" app state, and the view should be a function of this. In order to make this work, there is a ```Store``` type.

In RedCat, this comes in three main flavours:

1. The ```ObservableStore<State, Action>``` that can be observed using ```addObserver```. If Combine can be imported, this store is also known as ```CombineStore<State, Action>```.
2. The ```Store<Reducer>``` that is aware of the used recuder. This too is observable, in fact, ```ObservableStore<State, Action>``` is really just a type alias for ```Store<AnyReducer<State, Action>```.
3. The ```StoreStub<State, Action>``` which is seen by ```Service```s. This one has very limited functionalities in order to constrain the ```Services```.

Actions are sent to the store via its ```send``` or ```sendWithUndo``` methods. This is assumed to happen on the main thread. The action will then be enqueued, sent to the services (which may or may not enqueue further actions), sent to the reducer (which mutates the global state) and then sent to the services again (which may again enqueue further actions). This process is repeated until no service has further actions to enqueue (or they enqueue them asynchronously). For this whole process, the observers are notified exactly once.

Note that there is a ```StoreProtocol``` that ```ObservableStore``` and ```Store``` conform to. This one provides a whole lot of functionaility. It is not recommended though to conform to this directly. Instead, conform to ```StoreWrapper``` which plays the role of a decorator and comes with a lot of default implementations.

One noteworthy technicality: Store decorators (like e.g. the ```MapStore```) are designed in a way that they share their identity with some ```rootStore```. In order to make that possible, types conforming to ```StoreWrapper``` have to provide not only a ```wrapped``` store (which has the semantics of "the store with this decorator removed"), but also a method to recover this store from the ```wrapped``` store. Usually, you just hand the instance properties to a closure by value for that. The ```StoreWrapper``` protocol will then derive the ```rootStore``` with all decorators removed and a way to reconstruct the entire chain of decorators.

This way, you can create an API that makes it look like you are referring to a decorated store with a fixed identity while in reality, the decorated store may be created and destroyed all the time. RedCat uses this to implement ```sendWithUndo``` without making any assumptions about the lifecycle of decorated stores.

### Services

Every app has to handle side effects somehow. For this, RedCat has a dedicated ```DetailService``` class. This class exposes three methods that can be overridden: ```onAppInit```,  ```onUpdate``` and ```onShutdown```. The ```onUpdate``` method reacts to changes of some equatable property ("```Detail```") of the state that you can specify, the other two methods react to initialization and shutdown of the store.

In each of the above methods, you are able to access the ```DetailService```'s ```store``` property which allows you to send actions to the store or inspect the state. Additionally, you can use the ```Injected``` property wrapper to access the App's ```Dependencies``` (see below) during those methods.

The services are the perfect place to orchestrate further actions, either immediately or by registering an event listener and hopping back to the main queue whenever an event arrives. The ```Dependencies``` passed to the service are the ideal place to configure, e.g, the source of asynchronous events.

For discoverability, we recommend adding service types as nested types to ```Services```, a public "namespace" provided by RedCat.

### Environment

As mentioned above, services depend on some ```Dependencies``` type. This type works quite similarly to ```SwiftUI```'s environment, except it's named ```Dependencies``` in order to avoid name conflicts that break your property wrappers. The main way to work with this is as follows:

1. You declare some type that will be used as a key for ```Dependencies```' subscript:

```swift
enum MyKey : Dependency {
   static let defaultValue = "Hello, World!"
}
```

2. You add an instance property to ```Dependencies```:

```swift
extension Dependencies {
   var myValue : Int {
      get {self[MyKey.self]}
      set {self[MyKey.self] = newValue} //only required if you want to be able to change it
   }   
}
```

3. Optionally, you set specific values when building the environment:

```swift
let environment = Dependencies {
   Bind(\.myValue, to: "42")
}
```

There's a noteworthy distinction to ```SwiftUI```'s ```Environment```: The key type doesn't need to conform to ```Dependency```. There's actually a more general version of this: 

```swift
enum MyKey : Config {
   func value(given: Environment) -> Int {
      given.debug ? 1337 : 42
   }
}
```

This is very useful if the value usually only depends on other stored properties and only sometimes needs to be overridden.

Another key feature of ```Dependencies``` is memoization. Whenever the ```Dependencies``` instance doesn't find a stored value, it computes the default value - and stores it. This is done by reference (hence, the nonmutating getter), hence, if the associated value is a reference type, it will be retained. This is desirable whenever your dependency is designated for a service rather than a reducer. The only tradeoff is that reading environment values is not threadsafe and has to occur on the main thread.

## Proofs of Concept

There are two toy projects showcasing how RedCat is used.

- [RedCatTicTacToe](https://github.com/AnarchoSystems/RedCatTicTacToe): a Tic-Tac-Toe implementation using RedCat.
- [RedCatWeather](https://github.com/AnarchoSystems/RedCatWeather.git): a weather app communicating with a fake backend.

# Installation

## Swift Package Manager

In ```Package.swift```, add the following:

```swift
dependencies: [
        .package(url: "https://github.com/AnarchoSystems/RedCat.git", from: "0.3.1")
    ]
```

# Similar Projects 

I took a lot of inspiration from the following projects:

- [Elm](https://guide.elm-lang.org/)
- [Redux](https://redux.js.org/introduction/getting-started)
- [ReSwift](https://github.com/ReSwift/ReSwift)
- [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture)
- [RxFeedback](https://github.com/NoTests/RxFeedback.swift)

# Further Reading

- [How to cook reactive programming. Part 2: Side effects](https://habr.com/en/post/507290/)
