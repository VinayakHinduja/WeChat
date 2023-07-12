import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:we_chat/widgets/constants.dart';

import '../helpers/my_date_util.dart';
import '../models/chat_user.dart';

class ViewProfileScreen extends StatelessWidget {
  final ChatUser user;
  final void Function()? onTap;

  const ViewProfileScreen.mobile({
    super.key,
    required this.user,
  }) : onTap = null;

  const ViewProfileScreen.web({
    super.key,
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ScreenTypeLayout.builder(
      mobile: (BuildContext context) => mobileprofileScreen(context),
      desktop: (BuildContext context) => desktopProfileScreen(context),
    );
  }

  Widget mobileprofileScreen(BuildContext context) {
    Size mq = MediaQuery.of(context).size;

    return Scaffold(
      // app bar
      appBar: AppBar(title: Text(user.name)),

      //
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Joined On: ',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            MyDateUtill.getLastMessageTime(
              context,
              user.createdAt,
              showYear: true,
            ),
            style: const TextStyle(color: Colors.black54, fontSize: 20),
          ),
        ],
      ),

      // body
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: mq.width * .05),
        child: Column(
          children: [
            // for adding some space
            SizedBox(height: mq.height * .03, width: mq.width),

            // user profile picture and edit button
            ClipRRect(
              borderRadius: BorderRadius.circular(mq.height * .1),
              child: CachedNetworkImage(
                fit: BoxFit.fill,
                height: mq.height * .2,
                width: mq.height * .2,
                imageUrl: user.image,
                placeholder: (c, url) => const Icon(
                  size: 100,
                  CupertinoIcons.person,
                  color: Colors.black,
                ),
                errorWidget: (c, url, e) => Image.asset('images/person.png'),
              ),
            ),

            // for adding some space
            SizedBox(height: mq.height * .03),

            // email text
            Text(
              user.email,
              style: const TextStyle(color: Colors.black87, fontSize: 25),
            ),
            // for adding some space
            SizedBox(height: mq.height * .02),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'About: ',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  user.about,
                  style: const TextStyle(color: Colors.black54, fontSize: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget desktopProfileScreen(BuildContext context) {
    Size mq = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: kWebBackgroundColor,
      // app bar
      appBar: AppBar(
        title: Text(user.name),
        leading: IconButton(
          onPressed: onTap,
          icon: const Icon(Icons.close),
        ),
        backgroundColor: kWebAppBarColor,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      //
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Joined On: ',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            MyDateUtill.getLastMessageTime(
              context,
              user.createdAt,
              showYear: true,
            ),
            style: const TextStyle(color: Colors.black87, fontSize: 16),
          ),
        ],
      ),

      // body
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: mq.width * .01),
        child: Column(
          children: [
            // for adding some space
            SizedBox(height: mq.height * .03, width: mq.width),

            // user profile picture and edit button
            ClipRRect(
              borderRadius: BorderRadius.circular(mq.height * .1),
              child: CachedNetworkImage(
                fit: BoxFit.fill,
                height: mq.height * .2,
                width: mq.height * .2,
                imageUrl: user.image,
                placeholder: (c, url) => const Icon(
                  size: 100,
                  CupertinoIcons.person,
                  color: Colors.black,
                ),
                errorWidget: (c, url, e) => Image.asset('images/person.png'),
              ),
            ),

            // for adding some space
            SizedBox(height: mq.height * .03),

            // email text
            Text(
              user.email,
              style: const TextStyle(color: Colors.black87, fontSize: 16),
            ),
            // for adding some space
            SizedBox(height: mq.height * .02),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'About: ',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  user.about,
                  style: const TextStyle(color: Colors.black87, fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
