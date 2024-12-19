# ludi-mind

This repository contains a set of classes for building applications in a compositional way using Haxe macros. I expect that it will not really be used by anyone, but it showcases a template for compositional application building which I find to be universally applicable and maximally elegant.

The system includes the following components:

- [Component](#component): A base class for constructing a hierarchy of components.

Below are built-in components for facilitating application building:

- [Events](#events): An event system for subscribing to and dispatching events.
- [Intents](#intents): A system for handling requests and implementing features in a decoupled way.
- [EventNetwork](#eventnetwork): A system that allows building and triggering a graph of events.
- [Props](#props): A property system for managing and observing changes to properties.

## Quick Usage Example

```haxe
// System operations can be defined in decoupled enums for typing, or just as string literals for easy dynamically typed handlers.

enum MyProps<T> {
    PropExample: MyProps<Int>
}
enum MyEvents<T> {
    Event1: MyEvents<String>
}
enum MyIntents<Req, Res> {
    IntentExample: MyIntents<Int, String>;
}

// Accessing a typed property
myComponent.with(Props).of(PropExample).set(100); // Typed as Int

// Subscribing to a typed event
myComponent.with(Events).of(Event1).on(function(msg: String) {
    // Safely typed handler
});

// Making a typed intent request
myComponent.with(Intents).of(IntentExample).request(10, function(response: String) {
    // Safely typed response handling
});

```

## Component

The `Component` class allows for the composition of functionality by adding child components. Components can respond to events and manage their own child components.

```haxe
class OtherComponent extends Component { }

var parent = new Component();
var child = parent.with(OtherComponent); // Adds a child component of type OtherComponent
```

If you use the `with` macro with a non-component class, it wraps the class in a `VirtualComponent`:

```haxe
var nonCompInstance = parent.with(NonComponentClass); // Creates a VirtualComponent wrapping NonComponentClass. 
//nonCompInstance will still be of type NonComponentClass, because the with() macro function adds extra routing for virtual components.
```

## Props

The `Props` class provides a system for managing properties and observing changes. It allows accessing properties in a type-safe way using the `of()` function.


### Typed Usage with `of()`

- **Using a Class Type:**

  ```haxe
  var props = myComponent.with(Props);
  var propHandler = props.of(MyClass); // Access prop of type MyClass
  propHandler.set(myInstance);
  var value: MyClass = propHandler.get();
  ```

- **Using an Enum with Type Parameter:**

  Define an enum with one type parameter:

  ```haxe
  enum MyProps<T> {
      PropExample: MyProps<Int>
  }
  ```

  Access the prop with type inference:

  ```haxe
  var propHandler = props.of(PropExample); // Typed as Int
  propHandler.set(42);
  var value: Int = propHandler.get();
  ```

- **Using a String Literal:**

  ```haxe
  var propHandler = props.of("string literal name"); // Dynamic value
  propHandler.set(anyValue);
  var value = propHandler.get();
  ```

### Example

```haxe
myComponent.with(Props).of(PropExample).set(100); // Typed as Int
```

## Events

The `Events` class provides an event system for subscribing to and dispatching events. It supports typed event handling using the `of()` function.


### Typed Usage with `of()`

- **Using an Enum with Type Parameter:**

  Define an enum with one type parameter:

  ```haxe
  enum MyEvents<T> {
      Event1: MyEvents<String>
  }
  ```

  Subscribe and dispatch with type safety:

  ```haxe
  var events = myComponent.with(Events);
  events.of(Event1).on(function(payload: String) {
      // Handle event with payload of type String
  });

  events.of(Event1).dispatch("Hello, World!");
  ```

- **Using a String Literal:**

  ```haxe
  events.of("string literal name").on(function(payload: Dynamic) {
      // Handle event with dynamic payload
  });

  events.of("string literal name").dispatch(data);
  ```

### Example

```haxe
myComponent.with(Events).of(Event1).on(function(msg: String) {
    // Safely typed handler
});
```

## Intents

The `Intents` system allows for decoupled feature implementation by facilitating a request/response mechanism. It supports type-safe intent handling using the `of()` function.


### Typed Usage with `of()`

- **Using an Enum with Type Parameters:**

  Define an enum with two type parameters for request and response types:

  ```haxe
  enum MyIntents<Req, Res> {
      IntentExample: MyIntents<Int, String>;
  }
  ```

  Make requests and register handlers with type safety:

  ```haxe
  var intentRequest = myComponent.with(Intents).of(IntentExample);

  intentRequest.register(function(arg: Int): String {
      // Implement intent and return String
      return "Result " + arg;
  });

  var result = intentRequest.request(42); // Result is Option<String>
  ```

- **Using a String Literal:**

  ```haxe
  var intentRequest = intents.of("string literal name"); // Dynamic request and response
  intentRequest.register(function(arg: Dynamic): Dynamic {
      // Implement intent with dynamic types
      return dynamicResult;
  });

  var result = intentRequest.request(dynamicPayload);
  ```

### Example

```haxe
myComponent.with(Intents).of(IntentExample).request(10, function(response: String) {
    // Safely typed response handling
});
```

## EventNetwork

The `EventNetwork` class allows building and triggering a graph of events independently.

### Usage

```haxe
var network = myComponent.with(EventNetwork);

network.when("eventA", function() {
    trace("1");
    return EventNetworkReport.Complete("eventAProcessed");
});

network.when("eventAProcessed", function() {
    trace("2");
    return EventNetworkReport.Complete("eventBProcessed");
});

network.when("otherEvent", function() {
    trace("3");
    return EventNetworkReport.Complete("otherEventProcessed");
});

network.when("eventAProcessed", function() {
    trace("4");
    return EventNetworkReport.Complete("eventCProcessed");
});


network.fire("eventA");
//1
//2
//4
```