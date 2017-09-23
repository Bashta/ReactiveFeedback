//
//  SignalProducer+System.swift
//  ReactiveFeedback
//
//  Created by sergdort on 28/08/2017.
//  Copyright © 2017 sergdort. All rights reserved.
//

import Foundation
import ReactiveSwift
import enum Result.NoError

public typealias FeedbackLoop<State, Event> = (Signal<State, NoError>) -> Signal<Event, NoError>
public typealias Reducer<State, Event> = (State, Event) -> State

extension SignalProducerProtocol where Error == NoError {
    
    public static func system<Event>(initialState: Value,
                              reduce: @escaping Reducer<Value, Event>,
                              feedback: [FeedbackLoop<Value, Event>]) -> SignalProducer<Value, NoError> {
        return SignalProducer
            .deferred {
                let (subject, observer) = Signal<Value, NoError>.pipe()
                let events = Signal<Event, NoError>.merge(feedback.map { feedback in
                    return feedback(subject)
                })
                return SignalProducer(events.scan(initialState, reduce))
                    .prefix(value: initialState)
                    .on(value: observer.send(value:))
            }
    }
    
    public static func system<Event>(initialState: Value,
                              reduce: @escaping Reducer<Value, Event>,
                              feedback: FeedbackLoop<Value, Event>...) -> SignalProducer<Value, Error> {
        return system(initialState: initialState, reduce: reduce, feedback: feedback)
    }
    
    public static func system<Event>(initialState: Value,
                              reduce: @escaping Reducer<Value, Event>,
                              feedback: FeedbackLoop<Value, Event>) -> SignalProducer<Value, Error> {
        return system(initialState: initialState, reduce: reduce, feedback: feedback)
    }
}

extension SignalProducerProtocol {
    static func deferred(_ signalProducerFactory: @escaping () -> SignalProducer<Value, Error>) -> SignalProducer<Value, Error> {
        return SignalProducer<Void, Error>(value: ())
            .flatMap(.merge, signalProducerFactory)
    }
}
