import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart' as fb_ai;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as google_ai;
import '../config/api_config.dart';
import '../models/chat_message.dart';

class AIChatService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Google Generative AI (Free Gemini API Key)
  google_ai.GenerativeModel? _googleModel;
  google_ai.ChatSession? _googleChatSession;

  // Firebase Vertex AI
  fb_ai.GenerativeModel? _firebaseModel;
  fb_ai.ChatSession? _firebaseChatSession;

  bool get isUsingGeminiApiKey => ApiConfig.hasGeminiApiKey;
  String? get currentUserId => _auth.currentUser?.uid;

  AIChatService() {
    _initModel();
  }

  void _initModel() {
    if (ApiConfig.hasGeminiApiKey) {
      // Use direct Gemini API Key from Google AI Studio (100% Free)
      try {
        _googleModel = google_ai.GenerativeModel(
          model: 'gemini-3.5-flash-lite',
          apiKey: ApiConfig.geminiApiKey,
          systemInstruction: google_ai.Content.system(
            'You are ReEz AI, a smart, helpful, and friendly AI chatbot assistant. '
            'Provide clear, concise, accurate, and structured answers formatted nicely in markdown when appropriate.',
          ),
        );
        _googleChatSession = _googleModel?.startChat();
        debugPrint('AIChatService: Initialized with Google AI Studio Gemini API Key');
      } catch (e) {
        debugPrint('AIChatService: Error initializing Google AI: $e');
      }
    } else {
      // Fallback to Vertex AI in Firebase
      try {
        _firebaseModel = fb_ai.FirebaseAI.googleAI().generativeModel(
          model: 'gemini-2.0-flash',
          systemInstruction: fb_ai.Content.system(
            'You are ReEz AI, a smart, helpful, and friendly AI chatbot assistant. '
            'Provide clear, concise, accurate, and structured answers formatted nicely in markdown when appropriate.',
          ),
        );
        _firebaseChatSession = _firebaseModel?.startChat();
        debugPrint('AIChatService: Initialized with Vertex AI in Firebase');
      } catch (e) {
        debugPrint('AIChatService: Error initializing Firebase AI: $e');
      }
    }
  }

  /// Sends a message to the AI and streams text response chunks.
  Stream<String> sendMessageStream(String prompt) async* {
    if (ApiConfig.hasGeminiApiKey) {
      if (_googleChatSession == null) _initModel();
      if (_googleChatSession == null) {
        yield 'Error: Google AI model could not be initialized with your API key.';
        return;
      }

      try {
        final stream = _googleChatSession!.sendMessageStream(google_ai.Content.text(prompt));
        await for (final chunk in stream) {
          final text = chunk.text;
          if (text != null && text.isNotEmpty) {
            yield text;
          }
        }
      } catch (e) {
        debugPrint('Google AI Error: $e');
        yield '\n[Gemini API Error: $e. Please verify your API key in lib/config/api_config.dart]';
      }
    } else {
      // Try Firebase Vertex AI
      if (_firebaseChatSession == null) _initModel();

      try {
        if (_firebaseChatSession == null) {
          throw Exception('Firebase AI model not initialized');
        }

        final stream = _firebaseChatSession!.sendMessageStream(fb_ai.Content.text(prompt));
        await for (final chunk in stream) {
          final text = chunk.text;
          if (text != null && text.isNotEmpty) {
            yield text;
          }
        }
      } catch (e) {
        debugPrint('Firebase AI Error: $e');
        yield '\n[Vertex AI in Firebase was not found or is not enabled for your project.\n\n'
            'To get the chatbot working for 100% FREE without billing/credit card:\n'
            '1. Go to https://aistudio.google.com/app/apikey and create a free Gemini API key.\n'
            '2. Open "lib/config/api_config.dart" and paste your key into "geminiApiKey".]';
      }
    }
  }

  /// Resets the current chat session memory.
  void resetChatSession() {
    if (ApiConfig.hasGeminiApiKey) {
      _googleChatSession = _googleModel?.startChat();
    } else {
      _firebaseChatSession = _firebaseModel?.startChat();
    }
  }

  /// Reference to user's message collection in Firestore.
  CollectionReference<Map<String, dynamic>>? get _messagesCollection {
    final uid = currentUserId;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('messages');
  }

  /// Saves a single chat message to Firestore.
  Future<void> saveMessage(ChatMessage message) async {
    final collection = _messagesCollection;
    if (collection == null) return;

    try {
      await collection.doc(message.id).set(message.toMap());
    } catch (e) {
      debugPrint('Firestore saveMessage skipped or failed: $e');
    }
  }

  /// Loads previously saved messages from Firestore.
  Future<List<ChatMessage>> loadMessagesFromFirestore() async {
    final collection = _messagesCollection;
    if (collection == null) return [];

    try {
      final querySnapshot = await collection
          .orderBy('timestamp', descending: false)
          .limit(100)
          .get();

      return querySnapshot.docs.map((doc) {
        return ChatMessage.fromMap(doc.data(), docId: doc.id);
      }).toList();
    } catch (e) {
      debugPrint('Firestore loadMessages error: $e');
      return [];
    }
  }

  /// Clears saved messages from Firestore for the current user.
  Future<void> clearFirestoreHistory() async {
    final collection = _messagesCollection;
    if (collection == null) return;

    try {
      final snapshots = await collection.get();
      for (final doc in snapshots.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('Firestore clear error: $e');
    }
  }
}
