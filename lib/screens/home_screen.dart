// ignore_for_file: prefer_final_fields

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'package:responsive_builder/responsive_builder.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:we_chat/screens/chat_screen.dart';
import 'package:we_chat/widgets/constants.dart';

import '../main.dart';
import '../api/apis.dart';
import '../helpers/dialogs.dart';
import '../models/chat_user.dart';
import '../widgets/chat_user_card.dart';
import 'profile_screen.dart';
import 'view_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // for storing all users
  List<ChatUser> _list = [];

  // for storing searched items
  List<ChatUser> _searchList = [];

  // for storing search status
  bool _isSearching = false;

  bool thirdScreen = false;

  bool _home = true;

  ChatUser? currentChatAcc;

  FocusNode focus = FocusNode();

  Widget secondScreenWidget = Container(
    decoration: const BoxDecoration(
      image: DecorationImage(
        fit: BoxFit.cover,
        image: AssetImage('images/section.png'),
      ),
    ),
  );

  Widget thirdScreenWidget = Container();

  @override
  void initState() {
    super.initState();
    Future(() async => await APIs.getSelfInfo());
    focus.addListener(() => _handleFocus());

    SystemChannels.lifecycle.setMessageHandler((message) {
      if (APIs.auth.currentUser != null) {
        if (message.toString().contains('pause')) {
          APIs.updateActiveStatus(false);
        }
        if (message.toString().contains('resume')) {
          APIs.updateActiveStatus(true);
        }
        if (message.toString().contains('inactive')) {
          APIs.updateActiveStatus(false);
        }
        if (message.toString().contains('detached')) {
          APIs.updateActiveStatus(false);
        }
      }
      return Future.value(message);
    });
  }

  @override
  void dispose() {
    focus.removeListener(() => _handleFocus());
    focus.dispose();
    super.dispose();
  }

  void _handleFocus() {
    if (focus.hasFocus) setState(() => _isSearching = true);
    if (!focus.hasFocus) setState(() => _isSearching = false);
  }

  void _handleChatOT<Widget>(ChatUser user) {
    if (currentChatAcc != user) {
      setState(
        () {
          currentChatAcc = user;
          if (thirdScreen) {
            thirdScreen = false;
            thirdScreenWidget = Container();
          }
          secondScreenWidget = ChatScreen.web(
            user: user,
            onTap: () {
              if (!thirdScreen) _handleViewProfileOT(user);
            },
          );
        },
      );
    }
  }

  void _handleViewProfileOT<Widget>(ChatUser user) {
    setState(
      () {
        thirdScreen = true;
        thirdScreenWidget = ViewProfileScreen.web(
          user: user,
          onTap: () {
            if (thirdScreen) {
              setState(() {
                thirdScreen = false;
                thirdScreenWidget = Container();
              });
            }
          },
        );
      },
    );
  }

  void _handleEditProfileOT<Widget>() {
    setState(() => _home = true);
  }

  @override
  Widget build(BuildContext context) {
    homeMq = MediaQuery.of(context).size;

    return ScreenTypeLayout.builder(
      mobile: (BuildContext context) => mobileHomeScreen(),
      desktop: (BuildContext context) => desktopHomeScreen(),
    );
  }

  Widget mobileHomeScreen() {
    return WillPopScope(
      onWillPop: () {
        if (_isSearching) {
          setState(() => _isSearching = !_isSearching);
          return Future.value(false);
        } else {
          return Future.value(true);
        }
      },
      child: Scaffold(
        // app bar
        appBar: AppBar(
          title: _isSearching
              ? TextField(
                  autofocus: true,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Search name or email ',
                  ),
                  cursorWidth: 1.5,
                  style: const TextStyle(fontSize: 17, letterSpacing: 1),
                  onChanged: (val) {
                    _searchList.clear();

                    for (var i in _list) {
                      if (i.name.toLowerCase().contains(val.toLowerCase()) ||
                          i.email.toLowerCase().contains(val.toLowerCase())) {
                        _searchList.add(i);
                      }

                      setState(() => _searchList);
                    }
                  },
                )
              : const Text('We Chat'),
          actions: [
            IconButton(
              tooltip: 'Search',
              onPressed: () => setState(() => _isSearching = !_isSearching),
              icon: Icon(_isSearching
                  ? CupertinoIcons.clear_circled
                  : Icons.person_search_rounded),
            ),
            IconButton(
              tooltip: 'Edit Profile',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen.mobile(user: APIs.me),
                ),
              ),
              icon: const Icon(Icons.more_vert),
            ),
          ],
        ),

        // floating action button to add new user
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 10, right: 10),
          child: FloatingActionButton(
            onPressed: () => _showAddChatUserDialogue(),
            child: const Icon(Icons.person_add_alt_1_rounded),
          ),
        ),

        // body
        body: StreamBuilder(
          stream: APIs.getMyUsersId(),
          builder: (ctx1, snapshot1) {
            switch (snapshot1.connectionState) {
              // data is loading
              case ConnectionState.waiting:
              case ConnectionState.none:
                return const Center(child: CircularProgressIndicator());

              // if some or all data is loaded then show it
              case ConnectionState.active:
              case ConnectionState.done:
                return StreamBuilder(
                  stream: APIs.getAllUsers(
                      snapshot1.data?.docs.map((e) => e.id).toList() ?? []),
                  builder: (ctx2, snapshot2) {
                    switch (snapshot2.connectionState) {
                      // data is loading
                      case ConnectionState.waiting:
                      case ConnectionState.none:
                        return const Center(child: CircularProgressIndicator());

                      // if some or all data is loaded then show it
                      case ConnectionState.active:
                      case ConnectionState.done:
                        final data = snapshot2.data?.docs;
                        _list = data
                                ?.map((e) => ChatUser.fromJson(e.data()))
                                .toList() ??
                            [];
                        if (_list.isNotEmpty) {
                          return ListView.builder(
                            itemCount: _isSearching
                                ? _searchList.length
                                : _list.length,
                            padding:
                                EdgeInsets.only(top: mobileMq.height * .01),
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (ctx, i) => ChatUserCard.mobile(
                                user: _isSearching ? _searchList[i] : _list[i]),
                          );
                        } else {
                          return noFriends();
                        }
                    }
                  },
                );
            }
          },
        ),
      ),
    );
  }

  Widget noFriends() {
    return const Center(
      child: Text(
        'No Friends added yet !! \n Add some ↘️',
        style: TextStyle(fontSize: 30),
      ),
    );
  }

  Future<void> _showAddChatUserDialogue() async {
    String email = '';

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        buttonPadding: EdgeInsets.zero,
        actionsPadding: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding:
            const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 10),
        title: const Row(
          children: [
            Icon(
              Icons.person_add_alt_1_rounded,
              color: Colors.blue,
              size: 26,
            ),
            Text('  Add User'),
          ],
        ),
        content: TextFormField(
          onChanged: (value) => email = value,
          decoration: InputDecoration(
            label: const Text('Email'),
            prefixIcon: const Icon(Icons.email_rounded, color: Colors.blue),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
        actions: [
          MaterialButton(
            onPressed: () => Navigator.pop(_),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 16,
              ),
            ),
          ),
          Container(
            width: 2,
            height: 20,
            decoration: BoxDecoration(
                color: Colors.grey, borderRadius: BorderRadius.circular(10)),
          ),
          MaterialButton(
            onPressed: () async {
              Navigator.pop(_);
              if (email.isNotEmpty) {
                await APIs.addChatUser(email).then((value) {
                  if (!value) {
                    Dialogs.showSnackbar(context, 'User does not Exists!');
                  }
                });
              }
            },
            child: const Text(
              'Add',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ************** Web widgets  **************

  Widget desktopHomeScreen() {
    return Scaffold(
      backgroundColor: kWebBackgroundColor,
      body: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: firstScreenWidget()),
          Expanded(
            flex: 3,
            child: secondScreenWidget,
          ),
          if (thirdScreen) Expanded(child: thirdScreenWidget),
        ],
      ),
    );
  }

  PreferredSizeWidget webAppBar() {
    return AppBar(
      backgroundColor: kWebAppBarColor,
      leading: InkWell(
        onTap: () => setState(() => _home = false),
        child: Container(
          margin: const EdgeInsets.all(6),
          child: ClipRRect(
            clipBehavior: Clip.antiAlias,
            borderRadius: BorderRadius.circular(75),
            child: CachedNetworkImage(
              fit: BoxFit.fill,
              width: 25,
              height: 25,
              filterQuality: FilterQuality.high,
              imageUrl: APIs.me.image,
              imageBuilder: (context, imageProvider) => Container(
                decoration:
                    BoxDecoration(image: DecorationImage(image: imageProvider)),
              ),
              placeholder: (c, url) => const Icon(
                size: 100,
                CupertinoIcons.person,
                color: Colors.black,
              ),
              errorWidget: (c, url, e) => Image.asset('images/person.png'),
            ),
          ),
        ),
      ),
      centerTitle: false,
      title: Text(APIs.me.name),
      actions: [
        IconButton(
          tooltip: 'Add friends',
          onPressed: () => _showAddChatUserDialogue(),
          icon: const Icon(Icons.person_add_alt_1_rounded),
        ),
      ],
    );
  }

  Widget firstScreenWidget() {
    return _home
        ? SingleChildScrollView(
            child: Column(
              children: [
                webAppBar(),
                webSearchBar(),
                webContactList(),
              ],
            ),
          )
        : ProfileScreen.web(user: APIs.me, onTap: _handleEditProfileOT);
  }

  Widget webSearchBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 13, right: 13, left: 13),
      child: TextField(
        focusNode: focus,
        // style: const TextStyle(fontSize: 17, letterSpacing: 1),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: 'Search name or email ',
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade300),
            borderRadius: const BorderRadius.all(Radius.circular(15.0)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
            borderRadius: BorderRadius.all(Radius.circular(15.0)),
          ),
        ),
        onChanged: (val) {
          _searchList.clear();

          for (var i in _list) {
            if (i.name.toLowerCase().contains(val.toLowerCase()) ||
                i.email.toLowerCase().contains(val.toLowerCase())) {
              _searchList.add(i);
            }

            setState(() => _searchList);
          }
        },
      ),
    );
  }

  Widget webContactList() {
    return StreamBuilder(
      stream: APIs.getMyUsersId(),
      builder: (ctx1, snapshot1) {
        switch (snapshot1.connectionState) {
          // data is loading
          case ConnectionState.waiting:
          case ConnectionState.none:
            return const Center(child: CircularProgressIndicator());

          // if some or all data is loaded then show it
          case ConnectionState.active:
          case ConnectionState.done:
            return StreamBuilder(
              stream: APIs.getAllUsers(
                  snapshot1.data?.docs.map((e) => e.id).toList() ?? []),
              builder: (ctx2, snapshot2) {
                switch (snapshot2.connectionState) {
                  // data is loading
                  case ConnectionState.waiting:
                  case ConnectionState.none:
                    return const Center(child: CircularProgressIndicator());

                  // if some or all data is loaded then show it
                  case ConnectionState.active:
                  case ConnectionState.done:
                    final data = snapshot2.data?.docs;
                    _list = data
                            ?.map((e) => ChatUser.fromJson(e.data()))
                            .toList() ??
                        [];
                    if (_list.isNotEmpty) {
                      return ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.only(top: 10),
                        itemCount:
                            _isSearching ? _searchList.length : _list.length,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (ctx, i) => ChatUserCard.web(
                          user: _isSearching ? _searchList[i] : _list[i],
                          onTap: () => _handleChatOT(_list[i]),
                        ),
                      );
                    } else {
                      return noFriends();
                    }
                }
              },
            );
        }
      },
    );
  }
}
