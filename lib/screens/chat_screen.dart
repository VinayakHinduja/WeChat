// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:responsive_builder/responsive_builder.dart';

import '../api/apis.dart';
import '../main.dart';
import '../models/message.dart';
import '../models/chat_user.dart';
import '../widgets/constants.dart';
import '../helpers/my_date_util.dart';
import '../widgets/message_card.dart';
import 'view_profile_screen.dart';

class ChatScreen extends StatefulWidget {
  final ChatUser user;
  final void Function()? onTap;

  const ChatScreen.mobile({super.key, required this.user}) : onTap = null;

  const ChatScreen.web({super.key, required this.user, required this.onTap});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Message> _list = [];

  late TextEditingController _textController;

  bool _showEmoji = false;

  bool _uploading = false;

  bool _paused = false;

  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    SystemChannels.lifecycle.setMessageHandler((message) {
      if (APIs.auth.currentUser != null) {
        if (message.toString().contains('pause')) {
          APIs.updateActiveStatus(false);
          setState(() => _paused = true);
        }
        if (message.toString().contains('resume')) {
          APIs.updateActiveStatus(true);
          setState(() => _paused = false);
        }
        if (message.toString().contains('inactive')) {
          APIs.updateActiveStatus(false);
          setState(() => _paused = true);
        }
        if (message.toString().contains('detached')) {
          APIs.updateActiveStatus(false);
          setState(() => _paused = true);
        }
      }
      return Future.value(message);
    });
  }

  @override
  void dispose() {
    SystemChannels.lifecycle
        .setMessageHandler((message) => Future.value(message));
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    chatMq = MediaQuery.of(context).size;

    return ScreenTypeLayout.builder(
      mobile: (BuildContext context) => mobileChatScreen(),
      desktop: (BuildContext context) => desktopChatScreen(),
    );
  }

  Widget _mobileAppBar() {
    return StreamBuilder(
      stream: APIs.getUserInfo(widget.user),
      builder: (context, snapshot) {
        final data = snapshot.data?.docs;
        final list =
            data?.map((e) => ChatUser.fromJson(e.data())).toList() ?? [];
        return InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewProfileScreen.mobile(user: widget.user),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.black54,
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(chatMq.height * .3),
                child: CachedNetworkImage(
                  fit: chatMq.width <= 500 ? BoxFit.fill : null,
                  height: chatMq.width <= 500
                      ? chatMq.height * .045
                      : chatMq.height * .035,
                  width: chatMq.width <= 500
                      ? chatMq.height * .045
                      : chatMq.height * .035,
                  imageUrl: list.isNotEmpty ? list[0].image : widget.user.image,
                  errorWidget: (c, url, e) => Image.asset('images/person.png'),
                  placeholder: (c, url) => const Icon(
                    size: 30,
                    CupertinoIcons.person,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    list.isNotEmpty ? list[0].name : widget.user.name,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    list.isNotEmpty
                        ? list[0].isOnline
                            ? 'Online'
                            : MyDateUtill.getLastActiveTime(
                                context: context,
                                lastActive: list[0].lastActive,
                              )
                        : MyDateUtill.getLastActiveTime(
                            context: context,
                            lastActive: widget.user.lastActive,
                          ),
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _webAppBar() {
    return StreamBuilder(
      stream: APIs.getUserInfo(widget.user),
      builder: (context, snapshot) {
        final data = snapshot.data?.docs;
        final list =
            data?.map((e) => ChatUser.fromJson(e.data())).toList() ?? [];

        ImageProvider? provider() {
          if (widget.user.image.isEmpty)
            return const AssetImage('images/person.png');
          if (list.isNotEmpty) return NetworkImage(list[0].image);
          if (list.isEmpty) return NetworkImage(widget.user.image);
          return const AssetImage('images/person.png');
        }

        return InkWell(
          onTap: widget.onTap,
          child: Row(
            children: [
              const SizedBox(width: 15),
              CircleAvatar(
                backgroundColor: Colors.grey[200],
                foregroundImage: provider(),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    list.isNotEmpty ? list[0].name : widget.user.name,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    list.isNotEmpty
                        ? list[0].isOnline
                            ? 'Online'
                            : MyDateUtill.getLastActiveTime(
                                context: context,
                                lastActive: list[0].lastActive,
                              )
                        : MyDateUtill.getLastActiveTime(
                            context: context,
                            lastActive: widget.user.lastActive,
                          ),
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _chatInputMobile() {
    Size chatMq = MediaQuery.of(context).size;

    return Padding(
      padding: EdgeInsets.symmetric(
          vertical: chatMq.height * .01, horizontal: chatMq.width * .025),
      child: Row(
        children: [
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Row(
                children: [
                  SizedBox(width: chatMq.width * .01),
                  IconButton(
                    onPressed: () => setState(() => _showEmoji = !_showEmoji),
                    icon: const Icon(
                      Icons.emoji_emotions_rounded,
                      color: Colors.blueAccent,
                      size: 26,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      autofocus: false,
                      controller: _textController,
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      onTap: () => _showEmoji
                          ? setState(() => _showEmoji = !_showEmoji)
                          : null,
                      decoration: const InputDecoration(
                        hintText: 'Type Something ...',
                        hintStyle: TextStyle(color: Colors.blueAccent),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      final List<XFile> images =
                          await ImagePicker().pickMultiImage(imageQuality: 60);
                      if (images.isNotEmpty)
                        for (var i in images) {
                          setState(() => _uploading = true);
                          await APIs.sendChatImage(widget.user, File(i.path));
                          setState(() => _uploading = false);
                        }
                    },
                    icon: const Icon(
                      Icons.image,
                      color: Colors.blueAccent,
                      size: 26,
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      final image = await ImagePicker().pickImage(
                          source: ImageSource.camera, imageQuality: 70);
                      if (image == null) return;
                      setState(() => _uploading = true);
                      await APIs.sendChatImage(widget.user, File(image.path));
                      setState(() => _uploading = false);
                    },
                    icon: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.blueAccent,
                      size: 26,
                    ),
                  ),
                  SizedBox(width: chatMq.width * .01),
                ],
              ),
            ),
          ),
          const SizedBox(width: 5),
          MaterialButton(
            onPressed: _sending
                ? null
                : () async {
                    if (_textController.text.isNotEmpty) {
                      setState(() => _sending = true);
                      if (_list.isEmpty) {
                        await APIs.sendFirstMessage(
                            widget.user, _textController.text, Type.text);
                      } else {
                        await APIs.sendMessage(
                            widget.user, _textController.text, Type.text);
                      }
                      _textController.clear();
                      setState(() => _sending = false);
                    }
                  },
            padding: const EdgeInsets.only(
              top: 15,
              bottom: 15,
              left: 15,
              right: 10,
            ),
            minWidth: 0,
            disabledElevation: 0,
            color: Colors.green,
            shape: const CircleBorder(),
            disabledColor: Colors.grey,
            child: const Icon(
              Icons.send,
              color: Colors.white,
              size: 28,
            ),
          )
        ],
      ),
    );
  }

  Widget _chatInputWeb() {
    Size chatMq = MediaQuery.of(context).size;

    return Padding(
      padding: EdgeInsets.symmetric(
          vertical: chatMq.height * .01, horizontal: chatMq.width * .025),
      child: Row(
        children: [
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Row(
                children: [
                  SizedBox(width: chatMq.width * .005),
                  IconButton(
                    onPressed: () => setState(() => _showEmoji = !_showEmoji),
                    icon: const Icon(
                      Icons.emoji_emotions_rounded,
                      color: Colors.blueAccent,
                      size: 26,
                    ),
                  ),
                  SizedBox(width: chatMq.width * .003),
                  Expanded(
                    child: TextField(
                      autofocus: false,
                      controller: _textController,
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      onTap: () => _showEmoji
                          ? setState(() => _showEmoji = !_showEmoji)
                          : null,
                      decoration: const InputDecoration(
                        hintText: 'Type Something ...',
                        hintStyle: TextStyle(color: Colors.blueAccent),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      FilePickerResult? images = await FilePicker.platform
                          .pickFiles(allowMultiple: true);

                      if (images == null) return;

                      if (images.files.isNotEmpty)
                        for (var i in images.files) {
                          setState(() => _uploading = true);
                          await APIs.sendChatImageWeb(
                            widget.user,
                            i.bytes!,
                            i.name,
                          );
                          setState(() => _uploading = false);
                        }
                    },
                    icon: const Icon(
                      Icons.image,
                      color: Colors.blueAccent,
                      size: 26,
                    ),
                  ),
                  SizedBox(width: chatMq.width * .005),
                ],
              ),
            ),
          ),
          const SizedBox(width: 5),
          MaterialButton(
            onPressed: _sending
                ? null
                : () async {
                    if (_textController.text.isNotEmpty) {
                      setState(() => _sending = true);
                      if (_list.isEmpty) {
                        await APIs.sendFirstMessage(
                            widget.user, _textController.text, Type.text);
                      } else {
                        await APIs.sendMessage(
                            widget.user, _textController.text, Type.text);
                      }
                      _textController.clear();
                      setState(() => _sending = false);
                    }
                  },
            padding: const EdgeInsets.only(
              top: 15,
              bottom: 15,
              left: 15,
              right: 10,
            ),
            minWidth: 0,
            disabledElevation: 0,
            color: Colors.green,
            shape: const CircleBorder(),
            disabledColor: Colors.grey,
            child: const Icon(
              Icons.send,
              color: Colors.white,
              size: 28,
            ),
          )
        ],
      ),
    );
  }

  Widget mobileChatScreen() {
    return SafeArea(
      child: WillPopScope(
        onWillPop: () {
          if (_showEmoji) {
            setState(() => _showEmoji = !_showEmoji);
            return Future.value(false);
          } else {
            return Future.value(true);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            flexibleSpace: _mobileAppBar(),
          ),
          backgroundColor: const Color.fromARGB(255, 221, 245, 255),
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder(
                  stream: APIs.getAllMessages(widget.user),
                  builder: (ctx, snapshot) {
                    switch (snapshot.connectionState) {
                      case ConnectionState.waiting:
                      case ConnectionState.none:
                        return const Center(
                          child: Text(
                            'Loading ...',
                            style: TextStyle(
                              fontSize: 25,
                              color: Colors.black54,
                            ),
                          ),
                        );

                      // if some or all data is loaded then show it
                      case ConnectionState.active:
                      case ConnectionState.done:
                        final data = snapshot.data?.docs;
                        _list = data
                                ?.map((e) => Message.fromJson(e.data()))
                                .toList() ??
                            [];

                        if (_list.isNotEmpty) {
                          return ListView.builder(
                            reverse: true,
                            itemCount: _list.length,
                            padding: EdgeInsets.only(top: chatMq.height * .01),
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (ctx, i) => MessageCard(
                              message: _list[i],
                              pause: _paused,
                            ),
                          );
                        } else {
                          return Center(
                            child: TextButton(
                              onPressed: _sending
                                  ? null
                                  : () async {
                                      setState(() => _sending = true);

                                      await APIs.sendFirstMessage(
                                          widget.user, 'Hii! 👋', Type.text);

                                      setState(() => _sending = false);
                                    },
                              child: const Text(
                                'Say Hii! 👋',
                                style: TextStyle(fontSize: 30),
                              ),
                            ),
                          );
                        }
                    }
                  },
                ),
              ),
              if (_uploading)
                const Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              _chatInputMobile(),
              if (_showEmoji)
                SizedBox(
                  height: chatMq.height * .35,
                  child: EmojiPicker(
                    textEditingController: _textController,
                    config: Config(
                      columns: 10,
                      emojiSizeMax: 32 * (Platform.isIOS ? 1.30 : 1.0),
                      bgColor: const Color.fromARGB(255, 221, 245, 255),
                      recentsLimit: 40,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget desktopChatScreen() {
    return GestureDetector(
      onTap: () {
        if (_showEmoji) setState(() => _showEmoji = !_showEmoji);
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: kWebAppBarColor,
          automaticallyImplyLeading: false,
          flexibleSpace: _webAppBar(),
        ),
        // backgroundColor: const Color.fromARGB(255, 221, 245, 255),
        backgroundColor: kWebBackgroundColor,
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder(
                stream: APIs.getAllMessages(widget.user),
                builder: (ctx, snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.waiting:
                    case ConnectionState.none:
                      return const Center(
                        child: Text(
                          'Loading ...',
                          style: TextStyle(
                            fontSize: 25,
                            color: Colors.black54,
                          ),
                        ),
                      );

                    // if some or all data is loaded then show it
                    case ConnectionState.active:
                    case ConnectionState.done:
                      final data = snapshot.data?.docs;
                      _list = data
                              ?.map((e) => Message.fromJson(e.data()))
                              .toList() ??
                          [];

                      if (_list.isNotEmpty) {
                        return ListView.builder(
                          reverse: true,
                          itemCount: _list.length,
                          padding: EdgeInsets.only(top: chatMq.height * .01),
                          physics: const BouncingScrollPhysics(),
                          itemBuilder: (ctx, i) => MessageCard(
                            message: _list[i],
                            pause: _paused,
                          ),
                        );
                      } else {
                        return Center(
                          child: TextButton(
                            onPressed: _sending
                                ? null
                                : () async {
                                    setState(() => _sending = true);

                                    await APIs.sendFirstMessage(
                                        widget.user, 'Hii! 👋', Type.text);

                                    setState(() => _sending = false);
                                  },
                            child: const Text(
                              'Say Hii! 👋',
                              style: TextStyle(fontSize: 30),
                            ),
                          ),
                        );
                      }
                  }
                },
              ),
            ),
            if (_uploading)
              const Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            _chatInputWeb(),
            if (_showEmoji)
              SizedBox(
                height: chatMq.height * .35,
                child: EmojiPicker(
                  textEditingController: _textController,
                  config: const Config(
                    columns: 21,
                    emojiSizeMax: 25,
                    bgColor: Color.fromARGB(255, 221, 245, 255),
                    recentsLimit: 40,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
