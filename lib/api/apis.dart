// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:we_chat/helpers/loading_screen.dart';
import 'package:we_chat/screens/profile_screen.dart';

import '../helpers/dialogs.dart';
import '../models/message.dart';
import '../models/chat_user.dart';

class APIs {
  // for authentication
  static FirebaseAuth auth = FirebaseAuth.instance;

  // for accessing cloud firestore database
  static FirebaseFirestore firestore = FirebaseFirestore.instance;

  // for accessing cloud firestore database
  static FirebaseStorage storage = FirebaseStorage.instance;

  // to return current user
  static User get user => auth.currentUser!;

  static String get imageUrl => me.image;

  // current user
  static late ChatUser me;

  // for accessing firebase messaging
  static FirebaseMessaging fMessaging = FirebaseMessaging.instance;

  // for checking if user exist or not?
  static Future<bool> userExists() async =>
      (await firestore.collection('users').doc(user.uid).get()).exists;

  // for adding the chat user
  static Future<bool> addChatUser(String email) async {
    final data = await firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    if (data.docs.isNotEmpty && data.docs.first.id != user.uid) {
      firestore
          .collection('users')
          .doc(user.uid)
          .collection('my_users')
          .doc(data.docs.first.id)
          .set({});
      return true;
    } else {
      return false;
    }
  }

  // for getting self info
  static Future<void> getSelfInfo() async {
    await firestore.collection('users').doc(user.uid).get().then(
      (user) async {
        if (user.exists) {
          me = ChatUser.fromJson(user.data()!);
          if (!kIsWeb) await getfirebaseMessagingToken();
          await APIs.updateActiveStatus(true);
        } else {
          await createUser().then((value) => getSelfInfo());
        }
      },
    );
  }

  // for creating a new user
  static Future<void> createUser() async {
    final time = DateTime.now().millisecondsSinceEpoch.toString();

    final chatUser = ChatUser(
      image: user.photoURL.toString(),
      about: "Hey, I am using We Chat !!",
      name: user.displayName.toString(),
      createdAt: time,
      lastActive: time,
      isOnline: false,
      id: user.uid,
      pushToken: '',
      email: user.email.toString(),
    );

    return await firestore
        .collection('users')
        .doc(user.uid)
        .set(chatUser.toJson());
  }

  // stream for getting all the id of my users from data base
  static Stream<QuerySnapshot<Map<String, dynamic>>> getMyUsersId() {
    return firestore
        .collection('users')
        .doc(user.uid)
        .collection('my_users')
        .snapshots();
  }

  // stream for getting all the users
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsers(
      List<String> userIds) {
    return firestore
        .collection('users')
        .where('id', whereIn: userIds.isEmpty ? [''] : userIds)
        .snapshots();
  }

  // for updating user info
  static Future<void> updateUserInfo() async {
    await firestore.collection('users').doc(user.uid).update({
      'name': me.name,
      'about': me.about,
    });
  }

  // for updating user profile image from gallery
  static Future<void> updatePhotoUrlGallery(BuildContext context) async {
    try {
      LoadingScreen().show(context: context, text: 'Please Wait...');
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);

      if (image == null) return;

      final ext = image.path.split('.').last;

      Reference ref = FirebaseStorage.instance
          .ref()
          .child('profile_pictures/${user.uid}.$ext');

      await ref.putFile(
          File(image.path), SettableMetadata(contentType: 'image/$ext'));

      me.image = await ref.getDownloadURL();

      await firestore
          .collection('users')
          .doc(user.uid)
          .update({'image': me.image});
      LoadingScreen().hide();
      // if (context.mounted)
      Navigator.pop(context);
    } catch (e) {
      LoadingScreen().hide();
      Dialogs.showSnackbar(context, 'Something went wrong');
      log('form update photo url gallery hashcode = ${e.hashCode}, runtimeType = ${e.runtimeType}');
    }
  }

  // for updating user profile image from camera
  static Future<void> updatePhotoUrlCarmera(BuildContext context) async {
    try {
      LoadingScreen().show(context: context, text: 'Please Wait...');
      final image = await ImagePicker().pickImage(source: ImageSource.camera);
      if (image == null) return;

      final ext = image.path.split('.').last;
      Reference ref = FirebaseStorage.instance
          .ref()
          .child('profile_pictures/${user.uid}.$ext');
      await ref.putFile(
          File(image.path), SettableMetadata(contentType: 'image/$ext'));
      me.image = await ref.getDownloadURL();
      await firestore
          .collection('users')
          .doc(user.uid)
          .update({'image': me.image});
      LoadingScreen().hide();
      // if (context.mounted)
      Navigator.pop(context);
    } catch (e) {
      LoadingScreen().hide();
      Dialogs.showSnackbar(context, 'Something went wrong');
      log('form update photo url camera hashcode = ${e.hashCode}, runtimeType = ${e.runtimeType}');
    }
  }

  // for deleting user profile pic
  static Future<void> deleteProfilePic(BuildContext context) async {
    try {
      if (me.image == "") return;

      Reference? ref;
      LoadingScreen().show(context: context, text: 'Please Wait...');

      if (me.image.startsWith('https://firebasestorage.googleapis.com')) {
        ref = FirebaseStorage.instance.refFromURL(me.image);
      }
      if (ref != null) await ref.delete();

      await firestore.collection('users').doc(user.uid).update({'image': ''});
      await APIs.getSelfInfo();
      LoadingScreen().hide();
      // if (context.mounted)
      Navigator.pop(context);
      Navigator.pop(context);
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ProfileScreen.mobile(user: me)));
    } catch (e) {
      LoadingScreen().hide();
      Dialogs.showSnackbar(context, 'Something went wrong');
      log('form delete photo url hashcode = ${e.hashCode}, runtimeType = ${e.runtimeType}');
    }
  }

  // stream for getting the user's Information
  static Stream<QuerySnapshot<Map<String, dynamic>>> getUserInfo(
      ChatUser chatUser) {
    return firestore
        .collection('users')
        .where('id', isEqualTo: chatUser.id)
        .snapshots();
  }

  // update or last active of the user
  static Future<void> updateActiveStatus(bool isOnline) async {
    await firestore.collection('users').doc(user.uid).update({
      'is_online': isOnline,
      'last_active': DateTime.now().millisecondsSinceEpoch.toString(),
      'push_token': me.pushToken,
    });
  }

  ///****************************** Chat Screen Related APIs ******************************/

  // chats (collection) --> conversation_id (doc) --> messages (collection) -->message (doc)

  // for getting conversation id
  static String getConversationID(String id) => user.uid.hashCode <= id.hashCode
      ? '${user.uid}_$id'
      : '${id}_${user.uid}';

  // stream for gell all the Messages
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllMessages(
      ChatUser user) {
    return firestore
        .collection('chats/${getConversationID(user.id)}/messages')
        .orderBy('sent', descending: true)
        .snapshots();
  }

  // for sending message
  static Future<void> sendMessage(
      ChatUser chatUser, String msg, Type type) async {
    // msg sent time also used as id
    final time = DateTime.now().millisecondsSinceEpoch.toString();

    // message to send
    final Message message = Message(
      toId: chatUser.id,
      msg: msg,
      read: '',
      type: type,
      fromId: user.uid,
      sent: time,
    );

    final ref = firestore
        .collection('chats/${getConversationID(chatUser.id)}/messages');
    await ref.doc(time).set(message.toJson()).then((value) =>
        sendPushNotification(chatUser, type == Type.text ? msg : 'Photo'));
  }

  // update read status of message
  static Future<void> updateMessageReadStatus(Message message) async {
    await firestore
        .collection('chats/${getConversationID(message.fromId)}/messages')
        .doc(message.sent)
        .update({'read': DateTime.now().millisecondsSinceEpoch.toString()});
  }

  // stream for getting the last message
  static Stream<QuerySnapshot<Map<String, dynamic>>> getLastMessage(
      ChatUser user) {
    return firestore
        .collection('chats/${getConversationID(user.id)}/messages')
        .orderBy('sent', descending: true)
        .limit(1)
        .snapshots();
  }

  // for sending images in chats
  static Future<void> sendChatImage(ChatUser chatUser, File file) async {
    final ext = file.path.split('.').last;

    final ref = storage.ref().child(
        'images/${getConversationID(chatUser.id)}/${DateTime.now().millisecondsSinceEpoch}.$ext');

    await ref.putFile(file, SettableMetadata(contentType: 'image/$ext')).then(
        (p0) => log('data transfered: ${p0.bytesTransferred / 1000} kbs'));

    final imageUrl = await ref.getDownloadURL();
    await sendMessage(chatUser, imageUrl, Type.image);
  }

  // for sending images in chats for website
  static Future<void> sendChatImageWeb(
      ChatUser chatUser, Uint8List image, String name) async {
    final ext = name.split('.').last.toLowerCase();

    final ref = storage.ref().child(
        'images/${getConversationID(chatUser.id)}/${DateTime.now().millisecondsSinceEpoch}.$ext');

    await ref.putData(image, SettableMetadata(contentType: 'image/$ext')).then(
        (p0) => log('data transfered: ${p0.bytesTransferred / 1000} kbs'));

    final imageUrl = await ref.getDownloadURL();
    await sendMessage(chatUser, imageUrl, Type.image);
  }

  // delete message
  static Future<void> deleteMessage(Message message) async {
    await firestore
        .collection('chats/${getConversationID(message.toId)}/messages')
        .doc(message.sent)
        .delete();

    if (message.type == Type.image) {
      await storage.refFromURL(message.msg).delete();
    }
  }

  // delete message
  static Future<void> updateMessage(Message message, String updatedMsg) async {
    await firestore
        .collection('chats/${getConversationID(message.toId)}/messages')
        .doc(message.sent)
        .update({'msg': updatedMsg});
  }

  /// ********* notification

  // for getting firebase messaging token
  static Future<void> getfirebaseMessagingToken() async {
    await fMessaging.requestPermission();

    await fMessaging.getToken().then((value) {
      if (value != null) me.pushToken = value;
    });
  }

  // for sending push notification
  static Future<void> sendPushNotification(
      ChatUser chatUser, String msg) async {
    try {
      final body = {
        "to": chatUser.pushToken,
        "notification": {
          "title": me.name,
          "body": msg,
          "android_channel_id": "chats",
        }
      };
      var res = await post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        body: jsonEncode(body),
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.authorizationHeader:
              'key=APIKEY',
        },
      );
      log(' res body: ${res.body}');
      log(' res statusCode: ${res.statusCode}');
    } catch (e) {
      log('\nsendPushNotification E: $e');
    }
  }

  // for adding an user to my users when first message is send
  static Future<void> sendFirstMessage(
    ChatUser chatUser,
    String msg,
    Type type,
  ) async {
    await firestore
        .collection('users')
        .doc(chatUser.id)
        .collection('my_users')
        .doc(user.uid)
        .set({}).then((value) => sendMessage(chatUser, msg, type));
  }
}
