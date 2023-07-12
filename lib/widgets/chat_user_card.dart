import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:responsive_builder/responsive_builder.dart';

import '../api/apis.dart';
import '../main.dart';
import '../models/message.dart';
import '../models/chat_user.dart';
import '../screens/chat_screen.dart';
import '../helpers/my_date_util.dart';
import '../widgets/profile_dialogue.dart';

class ChatUserCard extends StatefulWidget {
  final ChatUser user;
  final void Function()? onTap;

  const ChatUserCard.mobile({
    super.key,
    required this.user,
  }) : onTap = null;

  const ChatUserCard.web({
    super.key,
    required this.user,
    required this.onTap,
  });

  @override
  State<ChatUserCard> createState() => _ChatUserCardState();
}

class _ChatUserCardState extends State<ChatUserCard> {
  Message? _message;

  @override
  Widget build(BuildContext context) {
    return ScreenTypeLayout.builder(
      mobile: (BuildContext context) => mobileChatUserCard(),
      desktop: (BuildContext context) => desktopChatUserCard(),
    );
  }

  ImageProvider? provider() {
    if (widget.user.image.isEmpty) return const AssetImage('images/person.png');
    if (widget.user.image.isNotEmpty) return NetworkImage(widget.user.image);
    return const AssetImage('images/person.png');
  }

  Widget mobileChatUserCard() {
    return Card(
      margin:
          EdgeInsets.symmetric(horizontal: mobileMq.width * .03, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ChatScreen.mobile(user: widget.user))),
        child: StreamBuilder(
          stream: APIs.getLastMessage(widget.user),
          builder: (context, snapshot) {
            final data = snapshot.data?.docs;
            final list =
                data?.map((e) => Message.fromJson(e.data())).toList() ?? [];
            if (list.isNotEmpty) _message = list[0];
            return ListTile(
              //user profile picture
              leading: InkWell(
                onTap: () => showDialog(
                    context: context,
                    builder: (_) => ProfileDialogue(user: widget.user)),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.transparent,
                      foregroundImage: provider(),
                    ),
                    if (widget.user.isOnline)
                      Positioned(right: 0, bottom: 0, child: greenCircle()),
                  ],
                ),
              ),

              //user name
              title: Text(widget.user.name),

              //last message
              subtitle: _message != null
                  ? _message!.type == Type.image
                      ? _message!.fromId == APIs.user.uid
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                doubleTickIcon(),
                                const SizedBox(width: 7),
                                const Icon(Icons.image_rounded,
                                    color: Colors.black38, size: 20),
                                text(' Photo'),
                              ],
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.image_rounded,
                                    color: Colors.black38, size: 20),
                                text(' Photo'),
                              ],
                            )
                      : _message!.fromId == APIs.user.uid
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                doubleTickIcon(),
                                const SizedBox(width: 7),
                                Flexible(child: text(_message!.msg)),
                              ],
                            )
                          : text(_message!.msg)
                  : text(widget.user.about),

              //last message time
              trailing: _message == null
                  ? null
                  : _message!.read.isEmpty && _message!.fromId != APIs.user.uid
                      ? greenCircle()
                      : text(MyDateUtill.getLastMessageTime(
                          context, _message!.sent)),
            );
          },
        ),
      ),
    );
  }

  Widget desktopChatUserCard() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: homeMq.width * .01, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: widget.onTap,
        child: StreamBuilder(
          stream: APIs.getLastMessage(widget.user),
          builder: (context, snapshot) {
            final data = snapshot.data?.docs;
            final list =
                data?.map((e) => Message.fromJson(e.data())).toList() ?? [];
            if (list.isNotEmpty) _message = list[0];
            return ListTile(
              //user profile picture
              leading: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(homeMq.height * .1),
                    child: CachedNetworkImage(
                      fit: BoxFit.fill,
                      height: homeMq.height * .061,
                      width: homeMq.width * .03,
                      imageUrl: widget.user.image,
                      placeholder: (c, url) => const Icon(
                        size: 30,
                        CupertinoIcons.person,
                        color: Colors.black,
                      ),
                      errorWidget: (c, url, e) =>
                          Image.asset('images/person.png'),
                    ),
                  ),
                  if (widget.user.isOnline)
                    Positioned(right: 3, bottom: 0, child: greenCircle()),
                ],
              ),

              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),

              //user name
              title: Text(widget.user.name),

              //last message
              subtitle: _message != null
                  ? _message!.type == Type.image
                      ? _message!.fromId == APIs.user.uid
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                doubleTickIcon(),
                                const SizedBox(width: 7),
                                const Icon(Icons.image_rounded,
                                    color: Colors.black38, size: 20),
                                text(' Photo'),
                              ],
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.image_rounded,
                                    color: Colors.black38, size: 20),
                                text(' Photo'),
                              ],
                            )
                      : _message!.fromId == APIs.user.uid
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                doubleTickIcon(),
                                const SizedBox(width: 7),
                                Flexible(child: text(_message!.msg)),
                              ],
                            )
                          : text(_message!.msg)
                  : text(widget.user.about),

              //last message time
              trailing: _message == null
                  ? null
                  : _message!.read.isEmpty && _message!.fromId != APIs.user.uid
                      ? greenCircle()
                      : text(
                          MyDateUtill.getLastMessageTime(
                              context, _message!.sent),
                        ),
            );
          },
        ),
      ),
    );
  }

  Widget text(String text) {
    return Text(
      text,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: kIsWeb ? 12 : 14),
    );
  }

  Widget doubleTickIcon() {
    return Icon(
      Icons.done_all_rounded,
      color: _message!.read.isEmpty ? Colors.black38 : Colors.blue,
      size: kIsWeb ? 18 : 20,
    );
  }

  Widget greenCircle() {
    return Container(
      height: 10,
      width: 10,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.lightGreenAccent[400]),
    );
  }
}
