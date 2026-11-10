import 'social_auth.dart';

/// No native social SDK on this platform (web): the provider stays unconfigured and is hidden.
SocialSignIn? nativeSocialSignIn(String provider) => null;
