/*
 * DO NOT EDIT.
 *
 * Generated by the protocol buffer compiler.
 * Source: {{ file.name }}
 *
 */

/*
 * Copyright 2017, gRPC Authors All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import Foundation
import Dispatch
import gRPC
//-{% for service in file.service %}

/// Type for errors thrown from generated client code.
{{ access }} enum {{ .|clienterror:file,service }} : Error {
  case endOfStream
  case invalidMessageReceived
  case error(c: CallResult)
}

//-{% for method in service.method %}
//-{% if not method.clientStreaming and not method.serverStreaming %}
//-{% include "client-call-unary.swift" %}
//-{% endif %}
//-{% if not method.clientStreaming and method.serverStreaming %}
//-{% include "client-call-serverstreaming.swift" %}
//-{% endif %}
//-{% if method.clientStreaming and not method.serverStreaming %}
//-{% include "client-call-clientstreaming.swift" %}
//-{% endif %}
//-{% if method.clientStreaming and method.serverStreaming %}
//-{% include "client-call-bidistreaming.swift" %}
//-{% endif %}
//-{% endfor %}
/// Call methods of this class to make API calls.
{{ access }} class {{ .|serviceclass:file,service }} {
  private var channel: Channel

  /// This metadata will be sent with all requests.
  {{ access }} var metadata : Metadata

  /// This property allows the service host name to be overridden.
  /// For example, it can be used to make calls to "localhost:8080"
  /// appear to be to "example.com".
  {{ access }} var host : String {
    get {
      return self.channel.host
    }
    set {
      self.channel.host = newValue
    }
  }

  /// Create a client that makes insecure connections.
  {{ access }} init(address: String) {
    gRPC.initialize()
    channel = Channel(address:address)
    metadata = Metadata()
  }

  /// Create a client that makes secure connections.
  {{ access }} init(address: String, certificates: String?, host: String?) {
    gRPC.initialize()
    channel = Channel(address:address, certificates:certificates, host:host)
    metadata = Metadata()
  }

  //-{% for method in service.method %}
  //-{% if not method.clientStreaming and not method.serverStreaming %}
  /// Synchronous. Unary.
  {{ access }} func {{ method.name|lowercase }}(_ request: {{ method|input }})
    throws
    -> {{ method|output }} {
      return try {{ .|call:file,service,method }}(channel).run(request:request, metadata:metadata)
  }
  /// Asynchronous. Unary.
  {{ access }} func {{ method.name|lowercase }}(_ request: {{ method|input }},
                  completion: @escaping ({{ method|output }}?, CallResult)->())
    throws
    -> {{ .|call:file,service,method }} {
      return try {{ .|call:file,service,method }}(channel).start(request:request,
                                                 metadata:metadata,
                                                 completion:completion)
  }
  //-{% endif %}
  //-{% if not method.clientStreaming and method.serverStreaming %}
  /// Asynchronous. Server-streaming.
  /// Send the initial message.
  /// Use methods on the returned object to get streamed responses.
  {{ access }} func {{ method.name|lowercase }}(_ request: {{ method|input }}, completion: @escaping (CallResult)->())
    throws
    -> {{ .|call:file,service,method }} {
      return try {{ .|call:file,service,method }}(channel).start(request:request, metadata:metadata, completion:completion)
  }
  //-{% endif %}
  //-{% if method.clientStreaming and not method.serverStreaming %}
  /// Asynchronous. Client-streaming.
  /// Use methods on the returned object to stream messages and
  /// to close the connection and wait for a final response.
  {{ access }} func {{ method.name|lowercase }}(completion: @escaping (CallResult)->())
    throws
    -> {{ .|call:file,service,method }} {
      return try {{ .|call:file,service,method }}(channel).start(metadata:metadata, completion:completion)
  }
  //-{% endif %}
  //-{% if method.clientStreaming and method.serverStreaming %}
  /// Asynchronous. Bidirectional-streaming.
  /// Use methods on the returned object to stream messages,
  /// to wait for replies, and to close the connection.
  {{ access }} func {{ method.name|lowercase }}(completion: @escaping (CallResult)->())
    throws
    -> {{ .|call:file,service,method }} {
      return try {{ .|call:file,service,method }}(channel).start(metadata:metadata, completion:completion)
  }
  //-{% endif %}
  //-{% endfor %}
}
//-{% endfor %}
