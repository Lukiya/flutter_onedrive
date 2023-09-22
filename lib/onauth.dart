import 'package:flutter/cupertino.dart';
import 'package:oauth_webauth/oauth_webauth.dart';
// import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
// import 'package:http/http.dart' as http;

class OAuth2Helper {
// use flutter_web_auth_2
//   static Future<dynamic> browserAuth1({
//     required BuildContext? context,
//     required Uri authEndpoint,
//     required Uri tokenEndpoint,
//     required String callbackUrlScheme,
//     required String clientID,
//     required String redirectURL,
//     String? scopes,
//   }) async {
//     try {
//       // open browser to authorize endpoint
//       final result = await FlutterWebAuth2.authenticate(
//           url: authEndpoint.toString(), callbackUrlScheme: callbackUrlScheme);

// // get code
//       final code = Uri.parse(result).queryParameters['code'];

// // use code to exchange token
//       final resp = await http.post(tokenEndpoint, body: {
//         'client_id': clientID,
//         'redirect_uri': redirectURL,
//         'grant_type': 'authorization_code',
//         'code': code,
//       });

//       return resp;
//     } catch (err) {
//       return null;
//     }
//   }

// use oauth_webauth
  static Future<dynamic> browserAuth({
    required BuildContext? context,
    required Uri authEndpoint,
    required Uri tokenEndpoint,
    required String callbackUrlScheme,
    required String clientID,
    required String redirectURL,
    String? scopes,
  }) async {
    try {
      final scopeArray = scopes?.split(" ");

      final result = await OAuthWebScreen.start(
        context: context!,
        configuration: OAuthConfiguration(
          authorizationEndpointUrl: authEndpoint.toString(),
          tokenEndpointUrl: tokenEndpoint.toString(),
          // clientSecret: clientSecret,
          clientId: clientID,
          redirectUrl: redirectURL,
          scopes: scopeArray,
          // promptValues: const ['login'],
          // loginHint: 'xxx@mail.com',
          onCertificateValidate: (certificate) {
            ///This is recommended
            /// Do certificate validations here
            /// If false is returned then a CertificateException() will be thrown
            return true;
          },
          // contentLocale: Locale('es'),
          // refreshBtnVisible: false,
          // clearCacheBtnVisible: false,
          // textLocales: {
          //   ///Optionally texts can be localized
          //   OAuthWebView.backButtonTooltipKey: 'Ir atrás',
          //   OAuthWebView.forwardButtonTooltipKey: 'Ir adelante',
          //   OAuthWebView.reloadButtonTooltipKey: 'Recargar',
          //   OAuthWebView.clearCacheButtonTooltipKey: 'Limpiar caché',
          //   OAuthWebView.closeButtonTooltipKey: 'Cerrar',
          //   OAuthWebView.clearCacheWarningMessageKey: '¿Está seguro que desea limpiar la caché?',
          // },
        ),
      );

      return result;
    } catch (err) {
      return null;
    }
  }
}
