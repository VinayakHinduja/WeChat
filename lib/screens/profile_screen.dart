// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:we_chat/widgets/constants.dart';

import '../api/apis.dart';
import '../helpers/dialogs.dart';
import '../main.dart';
import '../models/chat_user.dart';
import '../helpers/loading_screen.dart';
import 'auth/login_screen.dart';
import 'profile_pop_up_screen.dart';

class ProfileScreen extends StatefulWidget {
  final ChatUser user;
  final void Function()? onTap;

  const ProfileScreen.mobile({super.key, required this.user}) : onTap = null;

  const ProfileScreen.web({super.key, required this.user, required this.onTap});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return ScreenTypeLayout.builder(
      mobile: (BuildContext context) => mobileProfileScreen(),
      desktop: (BuildContext context) => desktopProfileScreen(),
    );
  }

  Widget mobileProfileScreen() {
    UniqueKey imageKey = UniqueKey();
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        // app bar
        appBar: AppBar(title: const Text('Edit Profile')),

        // floating action button for logout
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 10, right: 10),
          child: FloatingActionButton.extended(
            backgroundColor: Colors.red,
            onPressed: () async {
              LoadingScreen().show(context: context, text: 'Please wait ...');
              await APIs.updateActiveStatus(false);
              await APIs.auth.signOut().then(
                (value) async {
                  await GoogleSignIn().signOut().then(
                    (value) {
                      LoadingScreen().hide();
                      APIs.auth = FirebaseAuth.instance;
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (ctx) => const LoginScreen()),
                          (route) => false);
                    },
                  );
                },
              );
            },
            icon: const Icon(Icons.logout_sharp),
            label: const Text('Logout'),
          ),
        ),

        // body
        body: Form(
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: mobileMq.width * .05),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // for adding some space
                  SizedBox(
                      height: mobileMq.height * .03, width: mobileMq.width),
                  // user profile picture and edit button
                  Stack(
                    children: [
                      // user profile picture
                      CachedNetworkImage(
                        key: imageKey,
                        imageUrl: widget.user.image,
                        imageBuilder: (context, imageProvider) => CircleAvatar(
                          radius: mobileMq.height * .1,
                          backgroundColor: Colors.transparent,
                          backgroundImage: imageProvider,
                        ),
                        placeholder: (context, url) => CircleAvatar(
                          radius: mobileMq.height * .1,
                          backgroundColor: Colors.grey,
                        ),
                        errorWidget: (context, url, error) => CircleAvatar(
                          radius: mobileMq.height * .1,
                          backgroundColor: Colors.grey,
                          child: Image.asset('images/person.png'),
                        ),
                      ),
                      // edit button
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: MaterialButton(
                          onPressed: () async {
                            await showModalBottomSheet(
                              context: context,
                              showDragHandle: true,
                              clipBehavior: Clip.antiAliasWithSaveLayer,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(25),
                                  topRight: Radius.circular(25),
                                ),
                              ),
                              builder: (context) => ProfilePopUp(
                                pickCameraImage: () =>
                                    APIs.updatePhotoUrlCarmera(context),
                                pickGalleryImage: () =>
                                    APIs.updatePhotoUrlGallery(context),
                                deleteImage: () =>
                                    APIs.deleteProfilePic(context),
                              ),
                            );
                            imageCache.clear();
                            setState(() => imageKey = UniqueKey());
                          },
                          height: 60,
                          color: Colors.white,
                          elevation: 1,
                          shape: const CircleBorder(),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.blue,
                            size: 30,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // for adding some space
                  SizedBox(height: mobileMq.height * .03),

                  // email text
                  Text(widget.user.email,
                      style:
                          const TextStyle(color: Colors.black54, fontSize: 26)),

                  // for adding some space
                  SizedBox(height: mobileMq.height * .05),

                  // name text field
                  TextFormField(
                    initialValue: widget.user.name,
                    onSaved: (val) => APIs.me.name = val ?? '',
                    validator: (val) =>
                        val != null && val.isNotEmpty ? null : 'Field Required',
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person, color: Colors.blue),
                      hintText: 'eg. Happy Singh',
                      label: const Text('Name'),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),

                  // for adding some space
                  SizedBox(height: mobileMq.height * .02),

                  // about text field
                  TextFormField(
                    initialValue: widget.user.about,
                    onSaved: (val) => APIs.me.about = val ?? '',
                    validator: (val) =>
                        val != null && val.isNotEmpty ? null : 'Field Required',
                    decoration: InputDecoration(
                      prefixIcon:
                          const Icon(Icons.info_outline, color: Colors.blue),
                      hintText: 'eg. Feeling Happy',
                      label: const Text('About'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  // for adding some space
                  SizedBox(height: mobileMq.height * .05),

                  // update button
                  ElevatedButton.icon(
                    onPressed: () async {
                      FocusScope.of(context).unfocus();
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        await APIs.updateUserInfo().then(
                          (value) => Dialogs.showSnackbar(
                            context,
                            'Updated Successfully',
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: const StadiumBorder(),
                      minimumSize:
                          Size(mobileMq.width * .5, mobileMq.height * .05),
                    ),
                    icon:
                        const Icon(Icons.mode_edit_outline_outlined, size: 30),
                    label: const Text(
                      'UPDATE',
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget desktopProfileScreen() {
    Size mq = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: kWebBackgroundColor,
        // app bar
        appBar: AppBar(
          title: const Text('Edit Profile'),
          backgroundColor: kWebAppBarColor,
          leading: IconButton(
            onPressed: widget.onTap,
            icon: const Icon(Icons.close),
          ),
        ),

        // floating action button for logout
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 10, right: 10),
          child: FloatingActionButton.extended(
            label: const Text('Logout'),
            icon: const Icon(Icons.logout_sharp),
            backgroundColor: Colors.red,
            onPressed: () async {
              LoadingScreen().show(context: context, text: 'Please wait ...');
              await APIs.updateActiveStatus(false);
              await APIs.auth.signOut().then(
                (_) async {
                  await GoogleSignIn().signOut().then(
                    (_) {
                      LoadingScreen().hide();
                      APIs.auth = FirebaseAuth.instance;
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (ctx) => const LoginScreen()),
                          (route) => false);
                    },
                  );
                },
              );
            },
          ),
        ),

        // body
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // user profile picture and edit button
                ClipRRect(
                  clipBehavior: Clip.antiAlias,
                  borderRadius: BorderRadius.circular(mq.height * .15),
                  child: CachedNetworkImage(
                    fit: BoxFit.fill,
                    width: mq.height * .25,
                    height: mq.height * .25,
                    filterQuality: FilterQuality.high,
                    imageUrl: widget.user.image.toString(),
                    placeholder: (c, url) => const Icon(
                      size: 100,
                      CupertinoIcons.person,
                      color: Colors.black,
                    ),
                    errorWidget: (c, url, e) =>
                        Image.asset('images/person.png'),
                  ),
                ),

                // email text
                Text(widget.user.email,
                    style:
                        const TextStyle(color: Colors.black54, fontSize: 20)),

                // for adding some space
                SizedBox(height: mq.height * .01),

                // name text field
                SizedBox(
                  width: mq.width * .25,
                  child: TextFormField(
                    initialValue: widget.user.name,
                    onSaved: (val) => APIs.me.name = val ?? '',
                    validator: (val) =>
                        val != null && val.isNotEmpty ? null : 'Field Required',
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.person, color: Colors.blue),
                      hintText: 'eg. Happy Singh',
                      label: const Text('Name'),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade300),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(15.0)),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                        borderRadius: BorderRadius.all(Radius.circular(15.0)),
                      ),
                    ),
                  ),
                ),

                // about text field
                SizedBox(
                  width: mq.width * .25,
                  child: TextFormField(
                    initialValue: widget.user.about,
                    onSaved: (val) => APIs.me.about = val ?? '',
                    validator: (val) =>
                        val != null && val.isNotEmpty ? null : 'Field Required',
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon:
                          const Icon(Icons.info_outline, color: Colors.blue),
                      hintText: 'eg. Feeling Happy',
                      label: const Text('About'),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade300),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(15.0)),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                        borderRadius: BorderRadius.all(Radius.circular(15.0)),
                      ),
                    ),
                  ),
                ),

                // for adding some space
                SizedBox(height: mq.height * .04, width: mq.width),

                // update button
                ElevatedButton.icon(
                  onPressed: () async {
                    FocusScope.of(context).unfocus();
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      await APIs.updateUserInfo().then(
                        (value) => Dialogs.showSnackbar(
                          context,
                          'Updated Successfully',
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: const StadiumBorder(),
                    minimumSize: Size(mq.width * .15, mq.height * .07),
                  ),
                  icon: const Icon(Icons.mode_edit_outline_outlined, size: 30),
                  label: const Text(
                    'UPDATE',
                    style: TextStyle(fontSize: 24),
                  ),
                ),

                // for adding some space
                SizedBox(height: mq.height * .1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


/*

enum _Pic { upload, remove }

 bool isHovered = false;
  Offset _tapPosition = Offset.zero;

  void _getTapPosition(TapDownDetails details) {
    final RenderBox referenceBox = context.findRenderObject() as RenderBox;
    setState(() =>
        _tapPosition = referenceBox.globalToLocal(details.globalPosition));
  }

  void _showContextMenu(BuildContext context) async {
    final RenderObject? overlay =
        Overlay.of(context).context.findRenderObject();

    final result = await showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(_tapPosition.dx, _tapPosition.dy, 100, 100),
        Rect.fromLTWH(
          0,
          0,
          overlay!.paintBounds.size.width,
          overlay.paintBounds.size.height,
        ),
      ),
      items: [
        const PopupMenuItem(
          value: _Pic.upload,
          child: Text('Upload photo'),
        ),
        const PopupMenuItem(
          value: _Pic.remove,
          child: Text('Remove Photo'),
        ),
      ],
    );
    // perform action on selected menu item
    switch (result) {
      case _Pic.upload:
        return APIs.updatePhotoUrlGallery();
      case _Pic.remove:
        return APIs.deleteProfilePic();
      default:
    }
  }

ClipRRect(
                clipBehavior: Clip.antiAlias,
                borderRadius: BorderRadius.circular(mq.height * .15),
                child: GestureDetector(
                  onTapDown: _getTapPosition,
                  onTap: () => _showContextMenu(context),
                  child: MouseRegion(
                    onEnter: (_) => setState(() => isHovered = true),
                    onExit: (_) => setState(() => isHovered = false),
                    child: Stack(
                      children: [
                        CachedNetworkImage(
                          fit: BoxFit.fill,
                          width: mq.height * .25,
                          height: mq.height * .25,
                          filterQuality: FilterQuality.high,
                          imageUrl: widget.user.image.toString(),
                          placeholder: (c, url) => const Icon(
                            size: 100,
                            CupertinoIcons.person,
                            color: Colors.black,
                          ),
                          errorWidget: (c, url, e) =>
                              Image.asset('images/person.png'),
                        ),
                        Positioned.fill(
                          child: Visibility(
                            visible: isHovered,
                            child: Container(
                              color: Colors.black54,
                              child: const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      'CHANGE \nPROFILE PHOTO',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w100,
                                        letterSpacing: .5,
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),



 */