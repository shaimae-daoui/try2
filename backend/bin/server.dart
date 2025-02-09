import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

void main() async {
  // Create a WebSocket server
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 3000);
  print('WebSocket server running on ws://localhost:3000');

  await for (HttpRequest request in server) {
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      // Handle WebSocket connection
      final socket = await WebSocketTransformer.upgrade(request);
      final channel = IOWebSocketChannel(socket);

      print('New WebSocket connection: ${request.connectionInfo?.remoteAddress}');

      // Listen for messages from clients
      channel.stream.listen((message) {
        print('Received: $message');
        // Broadcast the message to all connected clients
        channel.sink.add('Echo: $message');
      });
    } else {
      // Handle HTTP requests (optional)
      request.response
        ..statusCode = HttpStatus.ok
        ..write('WebSocket server is running')
        ..close();
    }
  }
}