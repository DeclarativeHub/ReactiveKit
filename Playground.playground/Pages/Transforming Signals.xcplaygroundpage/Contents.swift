//: [Previous](@previous)

import Foundation
import ReactiveKit
import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true

//: # Transforming Signals
//: Uncomment the `observe { ... }` line to explore the behaviour!

// Let's play with Pokemons! We've got the following squad:

let pokemons = SafeSignal(sequence: ["Ditto", "Scizor", "Pikachu", "Squirtle"])

// Let's start simple and print thier names in uppercase.
// To modify elements of a signal, we can use the map operator:

pokemons
    .map { $0.uppercased() }
//    .observe { print($0) }


// If we are interested only in some elements of the signal, for
// example in Pokemons whose name starts with "S", we can use the filter operator:

pokemons
    .filter { $0.hasPrefix("S") }
//    .observe { print($0) }

// Alright, we know names of our Pokemons, but we need more details about them to make this fun!
// Let's define a type that will represent our Pokemons:

struct Pokemon: Codable {
    let name: String
    let height: Int
    let weight: Int
}

// We will make use of an awesome API called PokéAPI to fetch the details.

/// Returns a signal that fetches the details of the Pokemon with the given name.
func fetchPokemonDetails(name: String) -> Signal<Pokemon, Error> {
    return Signal { // A signal that fetches data from the given URL
        print("Fetching Pokemon named", name)
        return try Data(
            contentsOf: URL(string: "https://pokeapi.co/api/v2/pokemon/\(name.lowercased())")!
        )
    }
    .map { try JSONDecoder().decode(Pokemon.self, from: $0) } // We then map the data by decoding it into our Pokemon type
}

// Now that we have a way of fetching Pokemon details, let's fetch the details of our squad.
// We will use one of the three `flatMap*` operators provided by ReactiveKit.

pokemons
    .flatMapConcat(fetchPokemonDetails)
//    .observe { print($0) }

// Awesome! What is a flat map operator? It's actually just a shorthand for two operators.
// One that maps signal elements into new signals and the other the flattens the
// resulting signal of signals into one signal. Huh?

// No worries, let's do this step by step:

pokemons
    // First we map names into signals that fetch Pokemons.
    // We map `String` elements into `Signal<Pokemon, Error>` elements.
    // That will give us a signal of type `Signal<Signal<Pokemon, Error>, Error>`
    .map(fetchPokemonDetails)
    // Signals whose elements are other signals are usually not what we need.
    // We need Pokemons and Pokemons are elements of the inner signals. Who do we get them out?
    // Simple, just use the `flatten` operator. It will unwrap elements from the inner signals into our signal.
    .flatten(.concat)
//    .observe { print($0) }

// There are few possible strategies of flattening a signal. Ctrl + Cmd click the type bellow to see them all:
FlattenStrategy.self

// Nice, we now know what flat mapping is. It's pretty much the same as flat mapping a Swift collection like an Array.
// As you have probably noticed by now, signals and collections have so much in common!
// The reason is that both of them represent sequences of elements. Collections represent sequences in space, i.e.
// in the computer memory, while signals represent sequences in time. Many functional operations that you remember
// from collections will also work on signals.

// How much does our squad weigh? With functional-reactive programming, something like that is simple to answer:

pokemons
    .flatMapConcat(fetchPokemonDetails)
    .reduce(0) { totalWeight, pokemon in totalWeight + pokemon.weight }
//    .observeNext { print("Total weight of our Pokemons is \($0) hectograms!") }

// Fetching Pokemons every time we need them is wasteful. We can improve that by fetching once and then sharing the results:

let pokemonDetails = pokemons
    .flatMapConcat(fetchPokemonDetails)
    .shareReplay()

// We can now use `pokemonDetails` signal many times without making redundant network calls.
// The call will be made only the first time `pokemonDetails` is observed.

pokemonDetails
//    .observe { print($0) }

// If we now observe it one more time, we won't see "Fetching..." in the console.

pokemonDetails
//    .observe { print($0) }

// Try commenting out `.shareReplay()` line and see what happens in that case!


// There are many more operators on signals. Let's go through few of them.

// When we are interested only in the first few elements, we can apply `take(first:)` operator:

pokemons
    .take(first: 2)
//    .observe { print($0) }

// Similarly, when we are interested in last few elements, we can apply `take(last:)` operator:

pokemons
    .take(last: 1)
//    .observe { print($0) }

// Sometimes we need to combine element from more than one signal. To pair them into tuple, there
// is a zip operator available

pokemons
    .zip(with: SafeSignal(sequence: 0...))
//    .observe { print($0) }

// Let's use the zip operator again to combine our Pokemon names with a signal that emits an integer
// every second. We can pass a closure to the zip operator that maps the pair into something else,
// in our case into the name, ignoring the number.

let aPokemonEverySecond = pokemons
    .zip(with: SafeSignal(sequence: 0..., interval: 1)) { name, index in name }

aPokemonEverySecond
//    .observe { print($0) }

// There are other ways to combine signals than zipping them.
// For example, we could just merge elements from the two signals as the arrive.

aPokemonEverySecond
    .merge(with: SafeSignal(sequence: ["Suicune", "Genesect", "Lugia"], interval: 0.8))
//    .observe { print($0) }

// There is also a combine latest operator that combines the latest emitted events
// from the two signals.

aPokemonEverySecond
    .combineLatest(with: SafeSignal(sequence: 0...6, interval: 0.5))
    .observe { print($0) }

//: [Next](@next)
