library flutter_onedrive;

import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_onedrive/onedrive_response.dart';
// import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:http/http.dart' as http;
import 'package:oauth_webauth/oauth_webauth.dart';
import 'dart:convert' show jsonDecode;

import 'token.dart';

class OneDrive with ChangeNotifier {
  static const String authHost = "login.microsoftonline.com";
  static const String authEndpoint = "https://$authHost/common/oauth2/v2.0/authorize";
  static const String tokenEndpoint = "https://$authHost/common/oauth2/v2.0/token";
  static const String apiEndpoint = "https://graph.microsoft.com/v1.0/";
  static const String errCANCELED = "CANCELED";
  static const _appRootFolder = "special/approot";
  static const _defaultRootFolder = "root";
  static const permissionFilesReadWriteAppFolder = "Files.ReadWrite.AppFolder";
  static const permissionFilesReadWriteAll = "Files.ReadWrite.All";
  static const permissionOfflineAccess = "offline_access";

  late final ITokenManager _tokenManager;
  late final String redirectURL;
  final String scopes;
  final String clientID;
  // final String callbackSchema;
  final String state;

  OneDrive({
    required this.clientID,
    required this.redirectURL,
    this.scopes = "$permissionFilesReadWriteAll $permissionOfflineAccess",
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
        configuration: OAuthConfiguration(
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
        ),
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
        notifyListeners();
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
    notifyListeners();
  }

  Future<OneDriveResponse> pull(String remotePath, {bool isAppFolder = false}) async {
    final accessToken = await _tokenManager.getAccessToken();
    if (accessToken == null) {
      return OneDriveResponse(message: "Null access token", bodyBytes: Uint8List(0));
    }

    /// We need to call this method to create app folder and make sure it exists.
    /// Otherwise, we will get "Access Denied - 403".
    /// https://learn.microsoft.com/en-us/onedrive/developer/rest-api/concepts/special-folders-appfolder?view=odsp-graph-online
    if (isAppFolder) {
      await getMetadata(remotePath, isAppFolder: isAppFolder);
    }

    final url = Uri.parse("${apiEndpoint}me/drive/${_getRootFolder(isAppFolder)}:$remotePath:/content");

    try {
      final resp = await http.get(
        url,
        headers: {"Authorization": "Bearer $accessToken"},
      );

      debugPrint("# OneDrive -> pull: ${resp.statusCode}\n# Body: ${resp.body}");

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        return OneDriveResponse(statusCode: resp.statusCode, body: resp.body, message: "Download successfully.", bodyBytes: resp.bodyBytes, isSuccess: true);
      } else if (resp.statusCode == 404) {
        return OneDriveResponse(statusCode: resp.statusCode, body: resp.body, message: "File not found.", bodyBytes: Uint8List(0));
      } else {
        return OneDriveResponse(statusCode: resp.statusCode, body: resp.body, message: "Error while downloading file.", bodyBytes: Uint8List(0));
      }
    } catch (err) {
      debugPrint("# OneDrive -> pull: $err");
      return OneDriveResponse(message: "Unexpected exception: $err");
    }
  }

  Stream<UploadStatus> pushStream(Uint8List bytes, String remotePath, {bool isAppFolder = false}) async* {
    final accessToken = await _tokenManager.getAccessToken();
    if (accessToken == null) {
      // No access token
      throw Exception("Token is null");
    }

    /// We need to call this method to create app folder and make sure it exists.
    /// Otherwise, we will get "Access Denied - 403".
    /// https://learn.microsoft.com/en-us/onedrive/developer/rest-api/concepts/special-folders-appfolder?view=odsp-graph-online
    if (isAppFolder) {
      await getMetadata(remotePath, isAppFolder: isAppFolder);
    }

    const int pageSize = 1024 * 1024; // page size
    final int maxPage = (bytes.length / pageSize.toDouble()).ceil(); // total pages

// create upload session
// https://docs.microsoft.com/en-us/onedrive/developer/rest-api/api/driveitem_createuploadsession?view=odsp-graph-online
    var now = DateTime.now();
    var url = Uri.parse("$apiEndpoint/me/drive/${_getRootFolder(isAppFolder)}:$remotePath:/createUploadSession");
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

  Future<OneDriveResponse> push(Uint8List bytes, String remotePath, {bool isAppFolder = false}) async {
    final accessToken = await _tokenManager.getAccessToken();
    if (accessToken == null) {
      // No access token
      return OneDriveResponse(message: "Null access token.");
    }

    try {
      /// We need to call this method to create app folder and make sure it exists.
      /// Otherwise, we will get "Access Denied - 403".
      /// https://learn.microsoft.com/en-us/onedrive/developer/rest-api/concepts/special-folders-appfolder?view=odsp-graph-online
      if (isAppFolder) {
        await getMetadata(remotePath, isAppFolder: isAppFolder);
      }

      const int pageSize = 1024 * 1024; // page size
      final int maxPage = (bytes.length / pageSize.toDouble()).ceil(); // total pages

// create upload session
// https://docs.microsoft.com/en-us/onedrive/developer/rest-api/api/driveitem_createuploadsession?view=odsp-graph-online
      var now = DateTime.now();
      var url = Uri.parse("$apiEndpoint/me/drive/${_getRootFolder(isAppFolder)}:$remotePath:/createUploadSession");
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
            return OneDriveResponse(statusCode: resp.statusCode, body: resp.body, message: "Upload finished.", isSuccess: true);
          } else {
            // has issue
            return OneDriveResponse(statusCode: resp.statusCode, body: resp.body, message: "Upload failed.");
          }
        }
      }

      debugPrint("# Upload response: ${resp.statusCode}\n# Body: ${resp.body}");
    } catch (err) {
      debugPrint("# Upload error: $err");
      return OneDriveResponse(message: "Unexpected exception: $err");
    }

    return OneDriveResponse(message: "Unexpected error.");
  }

  String _getRootFolder(bool isAppFolder) {
    return isAppFolder ? _appRootFolder : _defaultRootFolder;
  }

  Future<Uint8List?> getMetadata(String remotePath, {bool isAppFolder = false}) async {
    final accessToken = await _tokenManager.getAccessToken();
    if (accessToken == null) {
      return Uint8List(0);
    }

    final url = Uri.parse("${apiEndpoint}me/drive/${_getRootFolder(isAppFolder)}");

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

      debugPrint("# OneDrive -> metadata: ${resp.statusCode}\n# Body: ${resp.body}");
    } catch (err) {
      debugPrint("# OneDrive -> metadata: $err");
    }

    return null;
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
