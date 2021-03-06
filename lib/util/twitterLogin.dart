import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:twisk/models/user.dart';
import 'package:twitter_oauth/twitter_oauth.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:twisk/screens/tasks_screen.dart';
import 'package:twisk/colors.dart';
import 'dart:async';
import 'package:twisk/util/database_helper.dart';
import 'package:twisk/apikey.dart';
import 'package:intl/intl.dart';
import 'package:twisk/models/user_data.dart';

class TwitterOauthPage extends StatefulWidget {
  const TwitterOauthPage({Key key}) : super(key: key);
  @override
  _TwitterOauthPageState createState() => _TwitterOauthPageState();
}

class _TwitterOauthPageState extends State<TwitterOauthPage> {
  TwitterOauth _twitterOauth;
  @override
  void initState() {
    super.initState();
    _twitterOauth = TwitterOauth(
      consumerKey,
      consumerSecret,
      callBackUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    bool _isDarkMode = isDark(context);
    return Scaffold(
      backgroundColor: getMainColor(_isDarkMode),
      body: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: EdgeInsets.only(
                  top: 45.0, left: 30.0, right: 30.0, bottom: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(48.0),
                        boxShadow: [
                          new BoxShadow(color: Colors.black12, blurRadius: 20.0)
                        ]),
                    child: Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        Container(
                          margin: EdgeInsets.only(right: 30),
                          child: CircleAvatar(
                            child: Icon(
                              Icons.dehaze,
                              size: 30.0,
                              color: getTextColor(_isDarkMode),
                            ),
                            backgroundColor: getTopButtonColor(_isDarkMode),
                            radius: 30.0,
                          ),
                        ),
                        Container(
                          width: 60,
                          height: 60,
                          margin: EdgeInsets.only(right: 30),
                          child: RawMaterialButton(
                            onPressed: () {
                              Scaffold.of(context).openDrawer();
                              Provider.of<UserData>(context).updateUserList();
                            },
                            shape: new CircleBorder(),
                            elevation: 0.0,
                          ),
                        )
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 10.0,
                  ),
                  Text(
                    'Login to Twitter',
                    style: TextStyle(
                      color: getTextColor(_isDarkMode),
                      fontSize: 50.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                decoration: BoxDecoration(
                  color: getListBackGroundColor(_isDarkMode),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20.0),
                    topRight: Radius.circular(20.0),
                    bottomLeft: Radius.circular(20.0),
                    bottomRight: Radius.circular(20.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor,
                      offset: Offset(2, 2),
                    )
                  ],
                ),
                margin: EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Container(
                      height: height * 0.12,
                      // height: height * 0.223214286,
                    ),
                    Container(
                        child: FutureBuilder<Widget>(
                      future: getDeleteButton(),
                      builder: (BuildContext context,
                          AsyncSnapshot<Widget> snapshot) {
                        if (snapshot.hasData) {
                          return snapshot.data;
                        }
                        return AlertDialog(
                          title: Text("error!"),
                        );
                      },
                    )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Widget> getDeleteButton() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    FirebaseUser user = await _auth.currentUser();
    if (user != null) {
      print("user exist");
      return ButtonTheme(
        minWidth: 150,
        height: 50,
        child: RaisedButton(
          child: Text(
            'Logout With Twitter.',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          color: Colors.redAccent,
          onPressed: () async {
            _signOut();
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => new TasksScreen()),
                (_) => false);
          },
        ),
      );
    } else {
      print("user doesn't exist");
      return ButtonTheme(
        minWidth: 150,
        height: 50,
        child: RaisedButton(
          child: const Text('Sign In With Twitter.'),
          onPressed: () async {
            final String authorizeUri = await _twitterOauth.getAuthorizeUri();
            Navigator.of(context).pushReplacement<Widget, Widget>(
              MaterialPageRoute<Widget>(
                builder: (BuildContext context) {
                  return TwitterWebView(
                    uri: authorizeUri,
                  );
                },
              ),
            );
          },
        ),
      );
    }
  }

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    _delete();
  }

  void _delete() async {
    DatabaseHelper helper = DatabaseHelper();
    int result = await helper.deleteUserData();
    if (result != 0) {
      Provider.of<UserData>(context).updateUserList();
    } else {
      print("failed to delete user data.");
    }
  }
}

class TwitterWebView extends StatefulWidget {
  const TwitterWebView({Key key, this.uri}) : super(key: key);
  final String uri;
  @override
  _TwitterWebViewState createState() => _TwitterWebViewState();
}

class _TwitterWebViewState extends State<TwitterWebView> {
  TwitterOauth _twitterOauth;

  @override
  void initState() {
    super.initState();
    _twitterOauth = TwitterOauth(
      consumerKey,
      consumerSecret,
      callBackUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WebView(
        initialUrl: widget.uri,
        javascriptMode: JavascriptMode.unrestricted,
        navigationDelegate: (NavigationRequest request) async {
          print("request.url:${request.url}");
          if (request.url.contains('handler')) {
            final String query = request.url.split('?').last;
            if (query.contains('denied') || query.contains('error')) {
              Navigator.of(context).pushReplacement<Widget, Widget>(
                MaterialPageRoute<Widget>(
                  builder: (BuildContext context) {
                    return (TasksScreen());
                  },
                ),
              );
              print("failed");
            } else {
              final Map<String, String> res = Uri.splitQueryString(query);
              twitterSignin(res).then(
                (String uid) {
                  Navigator.of(context).pushReplacement<Widget, Widget>(
                    MaterialPageRoute<Widget>(
                      builder: (BuildContext context) {
                        return (TasksScreen());
                      },
                    ),
                  );
                  // Navigator.pop(context);
                },
              );
            }
          } else {
            print("failed but not denied");
          }
          return NavigationDecision.navigate;
        },
      ),
    );
  }

  Future<String> twitterSignin(Map<String, String> token) async {
    final Map<String, String> oauthToken =
        await _twitterOauth.getAccessToken(token);
    final AuthCredential credential = TwitterAuthProvider.getCredential(
      authToken: oauthToken['oauth_token'],
      authTokenSecret: oauthToken['oauth_token_secret'],
    );
    final FirebaseUser user =
        (await FirebaseAuth.instance.signInWithCredential(credential)).user;
    _save(oauthToken);

    return user.uid;
  }

  void _save(oauthToken) async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    FirebaseUser firebaseUser = await _auth.currentUser();
    final displayName = firebaseUser.displayName;
    final screenName = oauthToken["screen_name"];
    final photoURL = firebaseUser.photoUrl;
    final userId = oauthToken["user_id"];
    final userOauthToken = oauthToken["oauth_token"];
    final userOauthTokenSecret = oauthToken["oauth_token_secret"];

    final date = DateFormat.yMMMd().format(DateTime.now());
    User userData = User(displayName, screenName, photoURL, userId, date,
        userOauthToken, userOauthTokenSecret);
    DatabaseHelper helper = DatabaseHelper();
    print("called insert method");
    await helper.insertUserData(userData).then((value) {
      print("added user(userId: ${value})");
    });
    Provider.of<UserData>(context).updateUserList();
  }
}
