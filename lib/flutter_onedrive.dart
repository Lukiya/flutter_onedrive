library flutter_onedrive;

import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:http/http.dart' as http;
import 'package:oauth_webauth/oauth_webauth.dart';
import 'dart:convert' show jsonDecode;

import 'token.dart';

class OneDrive {
  static const String authHost = "login.microsoftonline.com";
  static const String authEndpoint = "https://$authHost/common/oauth2/v2.0/authorize";
  static const String tokenEndpoint = "https://$authHost/common/oauth2/v2.0/token";
  static const String apiEndpoint = "https://graph.microsoft.com/v1.0/";
  static const String errCANCELED = "CANCELED";

  late final ITokenManager _tokenManager;
  late final String redirectURL;
  final String scopes;
  final String clientID;
  // final String callbackSchema;
  final String state;

  OneDrive({
    required this.clientID,
    required this.redirectURL,
    this.scopes = "offline_access Files.ReadWrite.All",
    this.state = "OneDriveState",
    ITokenManager? tokenManager,
  }) {
    // redirectURL = "$callbackSchema://auth";
    _tokenManager = tokenManager ??
        DefaultTokenManager(
          tokenEndpoint: tokenEndpoint,
          clientID: clientID,
          redirectURL: redirectURL,
          scope: scopes,
        );
  }

  Future<bool> isConnected() async {
    final accessToken = await _tokenManager.getAccessToken();
    return (accessToken?.isNotEmpty) ?? false;
  }

  Future<bool> connect(BuildContext context) async {
// Construct the url
    // final authUrl = Uri.https(authHost, authEndpoint, {
    //   'response_type': 'code',
    //   'client_id': clientID,
    //   'redirect_uri': redirectURL,
    //   'scopes': scope,
    //   'state': state,
    // });

// open browser to authorize endpoint
    try {
      // final result =
      //     await FlutterWebAuth.authenticate(url: authUrl.toString(), callbackUrlScheme: callbackSchema);

      final scopeArray = scopes.split(" ");

      final result = await OAuthWebScreen.start(
        context: context,
        authorizationEndpointUrl: authEndpoint,
        tokenEndpointUrl: tokenEndpoint,
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
      );

// // get code
//       final code = Uri.parse(result).queryParameters['code'];

// // use code to exchange token
//       final resp = await http.post(Uri.parse(tokenEndpoint), body: {
//         'client_id': clientID,
//         'redirect_uri': redirectURL,
//         'grant_type': 'authorization_code',
//         'code': code,
//       });

//  read token from Response
      if (result != null) {
        await _tokenManager.saveTokenResp(result);
        return true;
      }
    } on PlatformException catch (err) {
      if (err.code != errCANCELED) {
        debugPrint("# OneDrive -> connect: $err");
      }
    }

    return false;
  }

  Future<void> disconnect() async {
    await _tokenManager.clearStoredToken();
  }

  Future<Uint8List?> pull(String remotePath) async {
    final accessToken = await _tokenManager.getAccessToken();
    if (accessToken == null) {
      return Uint8List(0);
    }

    final url = Uri.parse("${apiEndpoint}me/drive/root:$remotePath:/content");

    try {
      final resp = await http.get(
        url,
        headers: {"Authorization": "Bearer $accessToken"},
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        return resp.bodyBytes;
      } else if (resp.statusCode == 404) {
        return Uint8List(0);
      }

      debugPrint("# OneDrive -> pull: ${resp.statusCode}\n# Body: ${resp.body}");
    } catch (err) {
      debugPrint("# OneDrive -> pull: $err");
    }

    return null;
  }

  Stream<UploadStatus> pushStream(Uint8List bytes, String remotePath) async* {
    final accessToken = await _tokenManager.getAccessToken();
    if (accessToken == null) {
      // No access token
      throw Exception("Token is null");
    }

    const int pageSize = 1024 * 1024; // page size
    final int maxPage = (bytes.length / pageSize.toDouble()).ceil(); // total pages

// create upload session
// https://docs.microsoft.com/en-us/onedrive/developer/rest-api/api/driveitem_createuploadsession?view=odsp-graph-online
    var now = DateTime.now();
    var url = Uri.parse("$apiEndpoint/me/drive/root:$remotePath:/createUploadSession");
    var resp = await http.post(
      url,
      headers: {"Authorization": "Bearer $accessToken"},
    );
    debugPrint("# Create Session: ${DateTime.now().difference(now).inMilliseconds} ms");

    if (resp.statusCode == 200) {
      // create session success
      final Map<String, dynamic> respJson = jsonDecode(resp.body);
      final String uploadUrl = respJson["uploadUrl"];
      url = Uri.parse(uploadUrl);

// use upload url to upload
      for (var pageIndex = 0; pageIndex < maxPage; pageIndex++) {
        now = DateTime.now();
        final int start = pageIndex * pageSize;
        int end = start + pageSize;
        if (end > bytes.length) {
          end = bytes.length; // cannot exceed max length
        }
        final range = "bytes $start-${end - 1}/${bytes.length}";
        final pageData = bytes.getRange(start, end).toList();
        final contentLength = pageData.length.toString();

        final headers = {
          "Authorization": "Bearer $accessToken",
          "Content-Length": contentLength,
          "Content-Range": range,
        };

        resp = await http.put(
          url,
          headers: headers,
          body: pageData,
        );

        final status = UploadStatus(pageIndex + 1, maxPage, start, end, contentLength, range);
        yield status;

        debugPrint(
            "# Upload [${pageIndex + 1}/$maxPage]: ${DateTime.now().difference(now).inMilliseconds} ms, start: $start, end: $end, contentLength: $contentLength, range: $range");

        if (resp.statusCode == 202) {
          // haven't finish, continue
          continue;
        } else if (resp.statusCode == 200 || resp.statusCode == 201) {
          // upload finished
          return;
        } else {
          // has issue
          throw Exception("Upload http error. [${resp.statusCode}]\n${resp.body}");
        }
      }
    } else {
      throw Exception("Create upload session http error [${resp.statusCode}]\n${resp.body}");
    }
  }

  Future<bool> push(Uint8List bytes, String remotePath) async {
    final accessToken = await _tokenManager.getAccessToken();
    if (accessToken == null) {
      // No access token
      return false;
    }

    try {
      const int pageSize = 1024 * 1024; // page size
      final int maxPage = (bytes.length / pageSize.toDouble()).ceil(); // total pages

// create upload session
// https://docs.microsoft.com/en-us/onedrive/developer/rest-api/api/driveitem_createuploadsession?view=odsp-graph-online
      var now = DateTime.now();
      var url = Uri.parse("$apiEndpoint/me/drive/root:$remotePath:/createUploadSession");
      var resp = await http.post(
        url,
        headers: {"Authorization": "Bearer $accessToken"},
      );
      debugPrint("# Create Session: ${DateTime.now().difference(now).inMilliseconds} ms");

      if (resp.statusCode == 200) {
        // create session success
        final Map<String, dynamic> respJson = jsonDecode(resp.body);
        final String uploadUrl = respJson["uploadUrl"];
        url = Uri.parse(uploadUrl);

// use upload url to upload
        for (var pageIndex = 0; pageIndex < maxPage; pageIndex++) {
          now = DateTime.now();
          final int start = pageIndex * pageSize;
          int end = start + pageSize;
          if (end > bytes.length) {
            end = bytes.length; // cannot exceed max length
          }
          final range = "bytes $start-${end - 1}/${bytes.length}";
          final pageData = bytes.getRange(start, end).toList();
          final contentLength = pageData.length.toString();

          final headers = {
            "Authorization": "Bearer $accessToken",
            "Content-Length": contentLength,
            "Content-Range": range,
          };

          resp = await http.put(
            url,
            headers: headers,
            body: pageData,
          );

          debugPrint(
              "# Upload [${pageIndex + 1}/$maxPage]: ${DateTime.now().difference(now).inMilliseconds} ms, start: $start, end: $end, contentLength: $contentLength, range: $range");

          if (resp.statusCode == 202) {
            // haven't finish, continue
            continue;
          } else if (resp.statusCode == 200 || resp.statusCode == 201) {
            // upload finished
            return true;
          } else {
            // has issue
            break;
          }
        }
      }

      debugPrint("# Upload response: ${resp.statusCode}\n# Body: ${resp.body}");
    } catch (err) {
      debugPrint("# Upload error: $err");
    }

    return false;
  }
}

class UploadStatus {
  final int index;
  final int total;
  final int start;
  final int end;
  final String contentLength;
  final String range;

  UploadStatus(this.index, this.total, this.start, this.end, this.contentLength, this.range);
}
