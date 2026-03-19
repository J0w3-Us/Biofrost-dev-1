import 'package:flutter/material.dart';

enum SocialType { github, linkedin, website }

extension SocialTypeX on SocialType {
  String get label => switch (this) {
        SocialType.github => 'GitHub',
        SocialType.linkedin => 'LinkedIn',
        SocialType.website => 'Sitio web',
      };

  IconData get icon => switch (this) {
        SocialType.github => Icons.code_rounded,
        SocialType.linkedin => Icons.link_rounded,
        SocialType.website => Icons.language_rounded,
      };

  String get hint => switch (this) {
        SocialType.github => 'https://github.com/usuario',
        SocialType.linkedin => 'https://linkedin.com/in/usuario',
        SocialType.website => 'https://mi-sitio.com',
      };

  String get emptySubtitle => switch (this) {
        SocialType.github => 'Conecta tu repositorio',
        SocialType.linkedin => 'Agrega tu perfil profesional',
        SocialType.website => 'Tu sitio personal',
      };
}
