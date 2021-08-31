//
//  PeerConnection.swift
//  Bitfinex Demo
//
//  Created by Jonathan Gikabu on 28/08/2021.
//

import Foundation
import Network

var sharedConnection: PeerConnection?

protocol PeerConnectionDelegate: AnyObject {
	func connectionReady()
	func connectionFailed()
	func receivedMessage(content: Data?, message: NWProtocolFramer.Message)
	func displayAdvertiseError(_ error: NWError)
}

class PeerConnection {

	weak var delegate: PeerConnectionDelegate?
	var connection: NWConnection?
	let initiatedConnection: Bool

	// Create an outbound connection when the user initiates a negotiation.
	init(endpoint: NWEndpoint, interface: NWInterface?, passcode: String, delegate: PeerConnectionDelegate) {
		self.delegate = delegate
		self.initiatedConnection = true

		let connection = NWConnection(to: endpoint, using: NWParameters(passcode: passcode))
		self.connection = connection
    
		startConnection()
	}

	// Handle an inbound connection when the user receives a negotiation request.
	init(connection: NWConnection, delegate: PeerConnectionDelegate) {
		self.delegate = delegate
		self.connection = connection
		self.initiatedConnection = false

		startConnection()
	}

	// Handle the user exiting the negotiation.
	func cancel() {
		if let connection = self.connection {
			connection.cancel()
			self.connection = nil
		}
	}

	// Handle starting the peer-to-peer connection for both inbound and outbound connections.
	func startConnection() {
		guard let connection = connection else {
			return
		}

		connection.stateUpdateHandler = { newState in
            print("!!!!!! ****** \(newState) state")
			switch newState {
			case .ready:

				// When the connection is ready, start receiving messages.
				self.receiveNextMessage()

				// Notify your delegate that the connection is ready.
				if let delegate = self.delegate {
					delegate.connectionReady()
				}
			case .failed(let error):
				print("\(connection) failed with \(error)")

				// Cancel the connection upon a failure.
				connection.cancel()

				// Notify your delegate that the connection failed.
				if let delegate = self.delegate {
					delegate.connectionFailed()
				}
			default:
				break
			}
		}

		// Start the connection establishment.
		connection.start(queue: .main)
	}

	func sendExchangeContent(_ content: String) {
		guard let connection = connection else {
			return
		}

		// Create a message object to hold the command type.
		let message = NWProtocolFramer.Message(messageType: .exchange)
		let context = NWConnection.ContentContext(identifier: "Exchange",
												  metadata: [message])

		// Send the application content along with the message.
		connection.send(content: content.data(using: .unicode), contentContext: context, isComplete: true, completion: .idempotent)
	}

	// Receive a message, deliver it to your delegate, and continue receiving more messages.
	func receiveNextMessage() {
		guard let connection = connection else {
			return
		}

		connection.receiveMessage { (content, context, isComplete, error) in
			// Extract your message type from the received context.
			if let message = context?.protocolMetadata(definition: ExchangeProtocol.definition) as? NWProtocolFramer.Message {
				self.delegate?.receivedMessage(content: content, message: message)
			}
			if error == nil {
				// Continue to receive more messages until you receive and error.
				self.receiveNextMessage()
			}
		}
	}
}
