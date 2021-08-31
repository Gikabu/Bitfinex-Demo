//
//  GameProtocol.swift
//  Bitfinex Demo
//
//  Created by Jonathan Gikabu on 28/08/2021.
//

import Foundation
import Network

enum MessageType: UInt32 {
	case invalid = 0
	case exchange = 1
}

class ExchangeProtocol: NWProtocolFramerImplementation {

	static let definition = NWProtocolFramer.Definition(implementation: ExchangeProtocol.self)

	static var label: String { return "Bitfinex" }

	// Set the default behavior for most framing protocol functions.
	required init(framer: NWProtocolFramer.Instance) { }
	func start(framer: NWProtocolFramer.Instance) -> NWProtocolFramer.StartResult { return .ready }
	func wakeup(framer: NWProtocolFramer.Instance) { }
	func stop(framer: NWProtocolFramer.Instance) -> Bool { return true }
	func cleanup(framer: NWProtocolFramer.Instance) { }

	// Whenever the application sends a message, add your protocol header and forward the bytes.
	func handleOutput(framer: NWProtocolFramer.Instance, message: NWProtocolFramer.Message, messageLength: Int, isComplete: Bool) {
		// Extract the type of message.
		let type = message.messageType

		// Create a header using the type and length.
		let header = ProtocolHeader(type: type.rawValue, length: UInt32(messageLength))

		// Write the header.
		framer.writeOutput(data: header.encodedData)

		// Ask the connection to insert the content of the application message after your header.
		do {
			try framer.writeOutputNoCopy(length: messageLength)
		} catch let error {
			print("Hit error writing \(error)")
		}
	}

	// Whenever new bytes are available to read, try to parse out your message format.
	func handleInput(framer: NWProtocolFramer.Instance) -> Int {
		while true {
			// Try to read out a single header.
			var tempHeader: ProtocolHeader? = nil
			let headerSize = ProtocolHeader.encodedSize
			let parsed = framer.parseInput(minimumIncompleteLength: headerSize,
										   maximumLength: headerSize) { (buffer, isComplete) -> Int in
				guard let buffer = buffer else {
					return 0
				}
				if buffer.count < headerSize {
					return 0
				}
				tempHeader = ProtocolHeader(buffer)
				return headerSize
			}

			// If you can't parse out a complete header, stop parsing and ask for headerSize more bytes.
			guard parsed, let header = tempHeader else {
				return headerSize
			}

			// Create an object to deliver the message.
			var messageType = MessageType.invalid
			if let parsedMessageType = MessageType(rawValue: header.type) {
				messageType = parsedMessageType
			}
			let message = NWProtocolFramer.Message(messageType: messageType)

			// Deliver the body of the message, along with the message object.
			if !framer.deliverInputNoCopy(length: Int(header.length), message: message, isComplete: true) {
				return 0
			}
		}
	}
}

// Extend framer messages to handle storing your command types in the message metadata.
extension NWProtocolFramer.Message {
	convenience init(messageType: MessageType) {
		self.init(definition: ExchangeProtocol.definition)
		self["MessageType"] = messageType
	}

	var messageType: MessageType {
		if let type = self["MessageType"] as? MessageType {
			return type
		} else {
			return .invalid
		}
	}
}

// Define a protocol header struct to help encode and decode bytes.
struct ProtocolHeader: Codable {
	let type: UInt32
	let length: UInt32

	init(type: UInt32, length: UInt32) {
		self.type = type
		self.length = length
	}

	init(_ buffer: UnsafeMutableRawBufferPointer) {
		var tempType: UInt32 = 0
		var tempLength: UInt32 = 0
		withUnsafeMutableBytes(of: &tempType) { typePtr in
			typePtr.copyMemory(from: UnsafeRawBufferPointer(start: buffer.baseAddress!.advanced(by: 0),
															count: MemoryLayout<UInt32>.size))
		}
		withUnsafeMutableBytes(of: &tempLength) { lengthPtr in
			lengthPtr.copyMemory(from: UnsafeRawBufferPointer(start: buffer.baseAddress!.advanced(by: MemoryLayout<UInt32>.size),
															  count: MemoryLayout<UInt32>.size))
		}
		type = tempType
		length = tempLength
	}

	var encodedData: Data {
		var tempType = type
		var tempLength = length
		var data = Data(bytes: &tempType, count: MemoryLayout<UInt32>.size)
		data.append(Data(bytes: &tempLength, count: MemoryLayout<UInt32>.size))
		return data
	}

	static var encodedSize: Int {
		return MemoryLayout<UInt32>.size * 2
	}
}
