import 'package:flutter/material.dart';
import 'package:wed_pic_frontend/models/media.dart';
import 'package:wed_pic_frontend/screens/session_explorer.dart';

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final List<Media> mediaItems = [
      Media(
          url:
              'https://helpx.adobe.com/content/dam/help/en/photoshop/using/convert-color-image-black-white/jcr_content/main-pars/before_and_after/image-before/Landscape-Color.jpg',
          type: 'image',
          name: 'Image 1',
          size: '150'),
      Media(
          url:
              'https://img-cdn.pixlr.com/image-generator/history/65bb506dcb310754719cf81f/ede935de-1138-4f66-8ed7-44bd16efc709/medium.webp',
          type: 'image',
          name: 'Video 1',
          size: '152'),
      Media(
        url:
            'https://images.unsplash.com/photo-1575936123452-b67c3203c357?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
        type: 'image',
        name: 'Image 2',
        size: '350',
      ),
      Media(
          url:
              'https://img.freepik.com/free-photo/abstract-autumn-beauty-multi-colored-leaf-vein-pattern-generated-by-ai_188544-9871.jpg?size=626&ext=jpg&ga=GA1.1.2008272138.1723507200&semt=ais_hybrid',
          type: 'image',
          name: 'Image 3',
          size: '200'),
      Media(
          url: 'https://fps.cdnpk.net/images/home/subhome-ai.webp?w=649&h=649',
          type: 'image',
          name: 'Image 4',
          size: '200'),
    ];

    return Scaffold(
      body: MediaGallery(mediaItems: mediaItems),
    );
  }
}
