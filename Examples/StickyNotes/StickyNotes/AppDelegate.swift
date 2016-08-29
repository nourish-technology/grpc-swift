/*
 *
 * Copyright 2016, Google Inc.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */
import Cocoa
import gRPC
import QuickProto

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  @IBOutlet weak var window: NSWindow!

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    gRPC.initialize()
    startServer(address:"localhost:8081")
  }

  func log(_ message: String) {
    print(message)
  }

  func startServer(address:String) {

    if let fileDescriptorSetProto =
      NSData(contentsOfFile:Bundle.main.path(forResource: "stickynote", ofType: "out")!) {
      // load a FileDescriptorSet that includes a descriptor for the messages we create and read
      let fileDescriptorSet = FileDescriptorSet(proto:fileDescriptorSetProto)

      DispatchQueue.global().async {
        self.log("Server Starting")
        self.log("GRPC version " + gRPC.version())

        let server = gRPC.Server(address:address)
        server.start()

        var requestCount = 0
        while(true) {
          let (callError, completionType, requestHandler) = server.getNextRequest(timeout:1.0)
          if (callError != GRPC_CALL_OK) {
            self.log("\(requestCount): Call error \(callError)")
            self.log("------------------------------")
          } else if (completionType == GRPC_OP_COMPLETE) {
            if let requestHandler = requestHandler {
              requestCount += 1
              self.log("\(requestCount): Received request " + requestHandler.host() + " " + requestHandler.method() + " from " + requestHandler.caller())
              let initialMetadata = requestHandler.requestMetadata
              for i in 0..<initialMetadata.count() {
                self.log("\(requestCount): Received initial metadata -> " + initialMetadata.key(index:i) + ":" + initialMetadata.value(index:i))
              }

              let initialMetadataToSend = Metadata()
              initialMetadataToSend.add(key:"a", value:"Apple")
              initialMetadataToSend.add(key:"b", value:"Banana")
              initialMetadataToSend.add(key:"c", value:"Cherry")
              let (_, _, message) = requestHandler.receiveMessage(initialMetadata:initialMetadataToSend)
              if let message = message {
                self.log("\(requestCount): Received message: \(message.data())")
                let requestMessage = fileDescriptorSet.readMessage(name:"StickyNoteRequest", proto:message.data())

                requestMessage?.forOneField(name:"message") {(field) in
                  let imageData = self.drawImage(message: field.string())

                  // construct an internal representation of the message
                  let replyMessage = fileDescriptorSet.createMessage(name:"StickyNoteResponse")!
                  replyMessage.addField(name:"image") {(field) in field.setData(imageData)}

                  let trailingMetadataToSend = Metadata()
                  trailingMetadataToSend.add(key:"0", value:"zero")
                  trailingMetadataToSend.add(key:"1", value:"one")
                  trailingMetadataToSend.add(key:"2", value:"two")
                  let (_, _) = requestHandler.sendResponse(message:ByteBuffer(data:replyMessage.serialize()),
                                                           trailingMetadata:trailingMetadataToSend)
                  self.log("------------------------------")
                }
              }
            }
          } else if (completionType == GRPC_QUEUE_TIMEOUT) {
            // everything is fine
          } else if (completionType == GRPC_QUEUE_SHUTDOWN) {
            // we should stop
          }
        }
      }
    }
  }

  func drawImage(message: String) -> NSData {
    let image = NSImage.init(size: NSSize.init(width: 400, height: 400),
                             flipped: false,
                             drawingHandler: { (rect) -> Bool in
                              NSColor.yellow.set()
                              NSRectFill(rect)
                              NSColor.black.set()
                              let string = NSString(string:message)
                              let trialS = CGFloat(300.0)
                              let trialFont = NSFont.userFont(ofSize:trialS)!
                              let trialAttributes = [NSFontAttributeName: trialFont]
                              let trialSize = string.size(withAttributes: trialAttributes)
                              let s = trialS * 300 / trialSize.width;
                              let font = NSFont.userFont(ofSize:s)!
                              let attributes = [NSFontAttributeName: font]
                              let size = string.size(withAttributes: attributes)
                              let x = rect.origin.x + 0.5*(rect.size.width - size.width)
                              let y = rect.origin.y + 0.5*(rect.size.height - size.height)
                              let r = NSMakeRect(x, y, size.width, size.height)
                              string.draw(in: r, withAttributes:attributes)
                              return true})
    let imgData: Data! = image.tiffRepresentation!
    let bitmap: NSBitmapImageRep! = NSBitmapImageRep(data: imgData)
    let pngImage = bitmap!.representation(using:NSBitmapImageFileType.PNG, properties:[:])
    return NSData(data:pngImage!)
  }
}

