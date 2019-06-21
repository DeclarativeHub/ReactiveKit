//
//  Completion.swift
//  ReactiveKit
//
//  Created by Srdan Rasic on 21/06/2019.
//  Copyright © 2019 DeclarativeHub. All rights reserved.
//

import Foundation

public enum Subscribers {

    public enum Completion<Failure> where Failure: Error {
        case finished
        case failure(Failure)
    }
}
