import 'package:flutter/material.dart';

class ProfilePopUp extends StatefulWidget {
  const ProfilePopUp({
    super.key,
    required this.pickCameraImage,
    required this.pickGalleryImage,
    required this.deleteImage,
  });

  final Function() pickGalleryImage;
  final Function() pickCameraImage;
  final Function() deleteImage;

  @override
  State<ProfilePopUp> createState() => _ProfilePopUpState();
}

class _ProfilePopUpState extends State<ProfilePopUp> {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 25),
          child: Column(
            children: [
              const SizedBox(height: 10),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Pick Profile Picture',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  // IconButton(
                  //   onPressed: () {},
                  //   icon: Icon(
                  //     Icons.delete,
                  //     color: Colors.grey.shade800,
                  //   ),
                  // )
                ],
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Buttons(
                    text: 'Camera',
                    icon: Icons.camera_alt_rounded,
                    onPressed: widget.pickCameraImage,
                  ),
                  const SizedBox(width: 30),
                  Buttons(
                    text: 'Gallery',
                    icon: Icons.insert_photo_rounded,
                    onPressed: widget.pickGalleryImage,
                  ),
                  const SizedBox(width: 30),
                  Buttons(
                    icon: Icons.delete,
                    text: 'Delete',
                    onPressed: widget.deleteImage,
                  ),
                ],
              ),
              const SizedBox(height: 45),
            ],
          ),
        )
      ],
    );
  }
}

class Buttons extends StatelessWidget {
  final Function() onPressed;
  final IconData icon;
  final String text;
  const Buttons({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 70,
          width: 70,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(
              icon,
              size: 42,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 15),
        Text(
          text,
          style: TextStyle(color: Colors.grey[800], fontSize: 17),
        ),
      ],
    );
  }
}
