//: [Previous](@previous)

import Foundation
import ReactiveKit
import PlaygroundSupport
import UIKit

PlaygroundPage.current.needsIndefiniteExecution = true

//: # Working with UI

// Let's play with Pokemons again!

struct Pokemon: Codable {
    let name: String
    let height: Int
    let weight: Int
}

// We will make a Pokemon profile view and fill it with a Pokemon details

class PokeProfile: UIView {
    let nameLabel = UILabel()
    let heightLabel = UILabel()
    let weightLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        let stackView = UIStackView(arrangedSubviews: [nameLabel, heightLabel, weightLabel])
        stackView.distribution = .fillEqually
        stackView.axis = .vertical
        stackView.frame = frame
        addSubview(stackView)
        backgroundColor = .white
    }
    required init?(coder aDecoder: NSCoder) { fatalError() }
}

// Open Assistent Editor to see the view!
let profileView = PokeProfile(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
PlaygroundPage.current.liveView = profileView

// Load the Pokemon from PokéAPI and bind it to the view.
// First we fetch the JSON response as Data
Signal { try Data(contentsOf: URL(string: "https://pokeapi.co/api/v2/pokemon/chandelure")!) }
    // Then decode the Pokemon type from the data
    .map { try JSONDecoder().decode(Pokemon.self, from: $0) }
    // Make sure we do the fetching and parsing on a non-main thread (queue)
    .executeOn(.global(qos: .utility))
    // We can only bind non-failable signals, so handle the potential error somehow
    .suppressError(logging: true)
    // Finally, bind the data to the view, ensuring the main thread
    .bind(to: profileView, context: .main) { view, pokemon in
        view.nameLabel.text = "Name: \(pokemon.name)"
        view.heightLabel.text = "Height: \(pokemon.height)"
        view.weightLabel.text = "Weight: \(pokemon.weight)"
    }

// Make sure to check out [Bond](https://github.com/DeclarativeHub/Bond) framework that
// provides many extensions that simplify usage of ReactiveKit in UI based apps.

//: [Next](@next)
