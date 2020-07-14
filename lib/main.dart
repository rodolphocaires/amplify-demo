import 'package:flutter/material.dart';
import 'package:flutter_aws_amplify_cognito/flutter_aws_amplify_cognito.dart';
import 'dart:convert' as convert;
import 'package:http/http.dart';
import 'package:local_auth/auth_strings.dart';
import 'package:otp/otp.dart';
import 'package:local_auth/local_auth.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        accentColor: Colors.amber[400],
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Token MFA'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  String secret;
  String token = '000000';
  TextEditingController _emailController = TextEditingController(text: 'rodolpho@live.de');
  TextEditingController _passwordController = TextEditingController(text: 'aws@Seph707');
  TextEditingController _codeController = TextEditingController();

  final LocalAuthentication auth = LocalAuthentication();

  void initState() {
    super.initState();
    _initialize();
  }

  void _initialize() async {
    UserStatus status = await FlutterAwsAmplifyCognito.initialize();
    switch (status) {
      case UserStatus.GUEST:
        _showSnackBar('Guest user');
        break;
      case UserStatus.SIGNED_IN:
        _showSnackBar('User signed in');
        break;
      case UserStatus.SIGNED_OUT:
        _showSnackBar('User signed out');
        break;
      case UserStatus.SIGNED_OUT_FEDERATED_TOKENS_INVALID:
        _showSnackBar('Federated tokens invalid');
        break;
      case UserStatus.SIGNED_OUT_USER_POOLS_TOKENS_INVALID:
        _showSnackBar('User pools tokens invalid');
        break;
      case UserStatus.UNKNOWN:
        _showSnackBar('User status unknown');
        break;
      case UserStatus.ERROR:
        _showSnackBar('Cognito error');
        break;
    }
  }

  void _showSnackBar(String message) {
    _scaffoldKey.currentState.showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(context).accentColor,
        content: Text(
          message,
          style: TextStyle(color: Theme.of(context).primaryColor),
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _register() async {
    Map<String, String> _userAttributes = Map<String, String>();
    _userAttributes['email'] = _emailController.text;
    _userAttributes['phone_number'] = '+5511975778490';

    try {
      SignUpResult result = await FlutterAwsAmplifyCognito.signUp(
        _emailController.text,
        _passwordController.text,
        _userAttributes,
      );

      if (!result.confirmationState) {
        final UserCodeDeliveryDetails details = result.userCodeDeliveryDetails;
        print(details.destination);
      } else {
        print('Sign Up Done!');
      }
    } catch (err) {
      if (err.details.contains('An account with the given email already exists.')) {
        _showSnackBar('Insert the received token.');
      } else {
        _showSnackBar(err.details);
      }
    }
  }

  void _verify() async {
    try {
      SignUpResult result = await FlutterAwsAmplifyCognito.confirmSignUp(
        _emailController.text,
        _codeController.text,
      );

      if (!result.confirmationState) {
        final UserCodeDeliveryDetails details = result.userCodeDeliveryDetails;
        print(details.destination);
      } else {
        _showSnackBar('User confirmed successfully');
        setState(() {
          _selectedIndex = 1;
        });
      }
    } catch (err) {
      _showSnackBar(err.details);
    }
  }

  void _login() async {
    try {
      SignInResult result = await FlutterAwsAmplifyCognito.signIn(
        _emailController.text,
        _passwordController.text,
      );

      _showSnackBar(result.signInState.toString());

      switch (result.signInState) {
        case SignInState.SMS_MFA:
          // TODO: Handle this case.

          break;
        case SignInState.PASSWORD_VERIFIER:
          // TODO: Handle this case.
          break;
        case SignInState.CUSTOM_CHALLENGE:
          // TODO: Handle this case.
          break;
        case SignInState.DEVICE_SRP_AUTH:
          // TODO: Handle this case.
          break;
        case SignInState.DEVICE_PASSWORD_VERIFIER:
          // TODO: Handle this case.
          break;
        case SignInState.ADMIN_NO_SRP_AUTH:
          // TODO: Handle this case.
          break;
        case SignInState.NEW_PASSWORD_REQUIRED:
          // TODO: Handle this case.
          break;
        case SignInState.DONE:
          // TODO: Handle this case.
          break;
        case SignInState.UNKNOWN:
          // TODO: Handle this case.
          break;
        case SignInState.ERROR:
          // TODO: Handle this case.
          break;
      }
    } catch (err) {
      _showSnackBar(err.details);
    }
  }

  void _smsAuth() async {
    try {
      SignInResult result = await FlutterAwsAmplifyCognito.confirmSignIn(_codeController.text);

      _showSnackBar(result.signInState.toString());

      switch (result.signInState) {
        case SignInState.SMS_MFA:
          // TODO: Handle this case.
          break;
        case SignInState.PASSWORD_VERIFIER:
          // TODO: Handle this case.
          break;
        case SignInState.CUSTOM_CHALLENGE:
          // TODO: Handle this case.
          break;
        case SignInState.DEVICE_SRP_AUTH:
          // TODO: Handle this case.
          break;
        case SignInState.DEVICE_PASSWORD_VERIFIER:
          // TODO: Handle this case.
          break;
        case SignInState.ADMIN_NO_SRP_AUTH:
          // TODO: Handle this case.
          break;
        case SignInState.NEW_PASSWORD_REQUIRED:
          // TODO: Handle this case.
          break;
        case SignInState.DONE:
          // TODO: Handle this case.
          break;
        case SignInState.UNKNOWN:
          // TODO: Handle this case.
          break;
        case SignInState.ERROR:
          // TODO: Handle this case.
          break;
      }
    } catch (err) {
      _showSnackBar(err.details);
    }
  }

  Widget _registerPage() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Column(
            children: <Widget>[
              TextFormField(
                keyboardType: TextInputType.emailAddress,
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'E-mail',
                ),
              ),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                ),
              ),
              SizedBox(height: 20),
              RaisedButton(
                onPressed: _register,
                color: Theme.of(context).primaryColor,
                padding: EdgeInsets.all(16),
                child: Text(
                  'Register',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              )
            ],
          ),
          Column(
            children: <Widget>[
              TextFormField(
                controller: _codeController,
                maxLength: 6,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Verification Code',
                ),
              ),
              SizedBox(height: 20),
              RaisedButton(
                onPressed: _verify,
                color: Theme.of(context).primaryColor,
                padding: EdgeInsets.all(16),
                child: Text(
                  'Verify',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _authPage() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Column(
            children: <Widget>[
              TextFormField(
                keyboardType: TextInputType.emailAddress,
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'E-mail',
                ),
              ),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                ),
              ),
              SizedBox(height: 20),
              RaisedButton(
                onPressed: _login,
                color: Theme.of(context).primaryColor,
                padding: EdgeInsets.all(16),
                child: Text(
                  'Login',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              )
            ],
          ),
          Column(
            children: <Widget>[
              TextFormField(
                controller: _codeController,
                maxLength: 6,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'SMS Code',
                ),
              ),
              SizedBox(height: 20),
              RaisedButton(
                onPressed: _smsAuth,
                color: Theme.of(context).primaryColor,
                padding: EdgeInsets.all(16),
                child: Text(
                  'Login',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _signedInPage() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          RaisedButton(
            color: Theme.of(context).primaryColor,
            onPressed: _isSignedIn,
            textColor: Colors.white,
            child: Text('Is signed in?'),
          ),
          RaisedButton(
            color: Theme.of(context).primaryColor,
            onPressed: _getUsername,
            textColor: Colors.white,
            child: Text('Get username'),
          ),
          RaisedButton(
            color: Theme.of(context).primaryColor,
            onPressed: _getIdentityId,
            textColor: Colors.white,
            child: Text('Get identity id'),
          ),
          RaisedButton(
            color: Theme.of(context).primaryColor,
            onPressed: _getUserAttributes,
            textColor: Colors.white,
            child: Text('Get user attributes'),
          ),
          RaisedButton(
            color: Theme.of(context).primaryColor,
            onPressed: _getTokens,
            textColor: Colors.white,
            child: Text('Get tokens'),
          ),
          RaisedButton(
            color: Theme.of(context).primaryColor,
            onPressed: _getIdToken,
            textColor: Colors.white,
            child: Text('Get id token'),
          ),
          RaisedButton(
            color: Theme.of(context).primaryColor,
            onPressed: _getAccessToken,
            textColor: Colors.white,
            child: Text('Get access token'),
          ),
          RaisedButton(
            color: Theme.of(context).primaryColor,
            onPressed: _getRefreshToken,
            textColor: Colors.white,
            child: Text('Get refresh token'),
          ),
          RaisedButton(
            color: Theme.of(context).primaryColor,
            onPressed: _getCredentials,
            textColor: Colors.white,
            child: Text('Get AWS Credentials'),
          ),
          RaisedButton(
            color: Theme.of(context).primaryColor,
            onPressed: _getDeviceDetails,
            textColor: Colors.white,
            child: Text('Get device details'),
          ),
        ],
      ),
    );
  }

  Widget _tokenPage() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          RaisedButton(
            color: Theme.of(context).primaryColor,
            onPressed: _generateToken,
            textColor: Colors.white,
            child: Text('Generate Token'),
          ),
          RaisedButton(
            color: Theme.of(context).primaryColor,
            onPressed: _checkBiometrics,
            textColor: Colors.white,
            child: Text('Check biometrics'),
          ),
          Container(
            margin: EdgeInsets.only(top: 100),
            alignment: Alignment.center,
            child: Text(
              token,
              style: TextStyle(
                fontSize: 60,
              ),
            ),
          )
        ],
      ),
    );
  }

  List<Widget> _widgets() {
    return <Widget>[
      _registerPage(),
      _authPage(),
      _signedInPage(),
      _tokenPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(widget.title),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.white,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add),
            title: Text('Register'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            title: Text('Authenticate'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.security),
            title: Text('Signed In'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.verified_user),
            title: Text('Token'),
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).accentColor,
        onTap: _onItemTapped,
      ),
      body: _widgets()[_selectedIndex],
    );
  }

  void _isSignedIn() async {
    try {
      bool result = await FlutterAwsAmplifyCognito.isSignedIn();
      print("Is user signed in? $result");
    } catch (err) {
      _showSnackBar(err.details);
    }
  }

  void _getUsername() async {
    try {
      String username = await FlutterAwsAmplifyCognito.getUsername();
      print('username is $username');
    } catch (err) {
      _showSnackBar(err.details);
    }
  }

  void _getIdentityId() async {
    try {
      String identityId = await FlutterAwsAmplifyCognito.getIdentityId();
      print('Identity ID is $identityId');
    } catch (err) {
      _showSnackBar(err.details);
    }
  }

  void _getUserAttributes() async {
    try {
      Map<String, String> userAttributes = await FlutterAwsAmplifyCognito.getUserAttributes();
      print('$userAttributes');
    } catch (err) {
      _showSnackBar(err.details);
    }
  }

  void _getTokens() async {
    try {
      Tokens tokens = await FlutterAwsAmplifyCognito.getTokens();
      print('Access Token: ${tokens.accessToken}');
      print('ID Token: ${tokens.idToken}');
      print('Refresh Token: ${tokens.refreshToken}');
    } catch (err) {
      _showSnackBar(err.details);
    }
  }

  void _getIdToken() async {
    try {
      String idToken = await FlutterAwsAmplifyCognito.getIdToken();
      print('ID Token: $idToken}');
    } catch (err) {
      _showSnackBar(err.details);
    }
  }

  void _getAccessToken() async {
    try {
      String accessToken = await FlutterAwsAmplifyCognito.getAccessToken();
      print('Access Token: $accessToken');
    } catch (err) {
      _showSnackBar(err.details);
    }
  }

  void _getRefreshToken() async {
    try {
      String refreshToken = await FlutterAwsAmplifyCognito.getRefreshToken();
      print('Refresh Token: $refreshToken');
    } catch (err) {
      _showSnackBar(err.details);
    }
  }

  void _getCredentials() async {
    try {
      AWSCredentials credentials = await FlutterAwsAmplifyCognito.getCredentials();
      print('Secret Key: ${credentials.secretKey}');
      print('Access Key: ${credentials.accessKey}');
    } catch (err) {
      _showSnackBar(err.details);
    }
  }

  void _getDeviceDetails() async {
    try {
      Device deviceDetails = await FlutterAwsAmplifyCognito.getDeviceDetails();
      print('createDate: ${deviceDetails.createDate}');
      print('deviceKey: ${deviceDetails.deviceKey}');
      print('lastAuthenticatedDate: ${deviceDetails.lastAuthenticatedDate}');
      print('lastModifiedDate: ${deviceDetails.lastModifiedDate}');
      print('attributes: ${deviceDetails.attributes}');
    } catch (err) {
      _showSnackBar(err.details);
    }
  }

  void _generateToken() async {
    try {
      bool _authenticated = await auth.authenticateWithBiometrics(
        localizedReason: 'Faça a leiura da sua biometria para autenticar',
        useErrorDialogs: true,
        androidAuthStrings: AndroidAuthMessages(
          fingerprintRequiredTitle: 'Biometria obrigatória',
          fingerprintNotRecognized: 'Biometria não reconhecida',
          cancelButton: 'Cancelar',
          goToSettingsButton: 'Configurar biometria',
          goToSettingsDescription:
              'Biometria não está configurada no seu dispositivo. Vá para \'Configurações > Segurança\' para adicionar sua biometria.',
        ),
        iOSAuthStrings: IOSAuthMessages(
          goToSettingsDescription:
              'Biometria não está configurada no seu dispositivo. Favor habilitar Touch ID ou Face ID no seu dispositivo.',
          cancelButton: 'Cancelar',
          goToSettingsButton: 'Configurar biometria',
          lockOut:
              'Biometria desabilitada. Bloqueie e desbloqueie a tela do seu dispositivo para habilitar',
        ),
        stickyAuth: true,
      );

      _showSnackBar('Is _authenticated: $_authenticated');

      if (!_authenticated) {
        return;
      }

      // Generate token
      if (secret != null) {
        String _token = OTP.generateTOTPCodeString(secret, DateTime.now().millisecondsSinceEpoch,
            algorithm: Algorithm.SHA1, isGoogle: true);
        setState(() => token = _token);
        return;
      }

      try {
        Response res = await post(
          'https://dev.avenuesec.io/api/auth/associatetoken',
          body: '{}',
          headers: {
            'Content-Type': 'application/json',
            'cookie':
                'refreshToken=eyJjdHkiOiJKV1QiLCJlbmMiOiJBMjU2R0NNIiwiYWxnIjoiUlNBLU9BRVAifQ.kMHkom13M2cQK4f75yrNVHRxWsVd0xpV20l3civL_7VTEY-n-btxmHAx-P8HtxTARzL19xlmtPsbR7WWvcrNsaCZtN4eL0VzxFvcVDSQ4SFff0c9mjin3jEik7M6W1mGWPwvcvmjVg2LcKlhqkO1qGOU8qG3C_rGhyyMh2EdJ-S6ZHgjqPiGlzuigS1NKAsZfi2HHqVWDX9d8OcLu3aAQI7S0S0W7MD3w6LY25X-eEpe0xDQPYON-bWA9-61X5TaSrDu0Q6bAbe3gKSu9ABRbNthVdASyOXtvU0VftFRKbohFTap9WH1EuJBbev2vLIB_dFQDhrq24G0hJZAZ4puRw.Ogfs2PVVB1TH0iRg.hAQvcU22sat7dEgssDpNsMp6qffjm8I66IYfrBnjKufMoi2hC-uKA6UYXhTKmLaZc9gKDaQ1s17k6gxAWtViG0sxUvlivQre5KbGy9-a7xI28VCZ2xKkyMQVYB5xmp8TavTKHRUhsX5boBQPvrnFq8oDvC9v_68SwNCfjuAHPJO_BGOwtOhwm5TgP8XY89EDH6bdxpcZ6KGI5jMXmWrO5Iv1sNTZ3O1c0e_geVOHPmcRVG5ndmdOHzhs1a_w8ZTZO21m7bcwVrbSShc0-93QELAHpTCRzjchsy3ceq3YHej3sR3Njh59YSsX3JGSJMEfBGNiTVyHlp0T3pUPtTP5UmHJUTtNWhT4lg_KP0lvPFM6_EX7Y4ZRaZDpgWGbIbI7cHdW4FDnRaGkAf_70Qt_0zmKXyY_s3jHLOAnjJIIjILudeks62lF-2WJOMZsZRbwqvSf6l2i3wKm4TRf2YZltvm6LQjr5hLHco3aYJwnoW12gMcGFrR63s8Ww_c0AbSjZKWoxqL7dzY7AYk0HOAgyq-ioW_gCQLPwbiSDG4Mnr3UqUIamI20ksAhBp02oLXhNe4V1m0ULcsT6fcR0n_LENGZ_g8pvC8aKgtWc9pcrlbOZ-477nEyxeyZftAD5FWxGnYQzn_OyhTGCr8eDd6a2e9RILXj53AnU6C0MeWzvUP4rqxv4lOlHzLa0E93OHIK9RLTIzOtN1bCbeRgy4WChY3WSZhhbnk9dYKssC6llEWvaUdut8a0p2nlcEtioJZ_1rh2lAZnSF7ccEzTsceIDvtDXYB5kDQNjgL6cBjaDKOPvcFf0i5y72AI4ecnan0b2tGqI_NYJGglpAmfTBvVj4VCpp763X43Itw8B5yXpQr2ryAKLLUUFD04gaARGo6Necx7kxsvmte5jTBB5JvGucBagSlDOmwdqgtXbHRpnQLpBesDXChSbDHq1wyKigpEjgPOosf5CAs9eEVlQsILmfxO8JgaPEAh0AVK7w_F7U-rDoXDJZU4jG5K0AlTjFc1aVNYGLU8J4zVWYMHKjB7FG6uHpYTSQxZGSIGJu8oajeyR_UqZemGQkSRlQn_0O0CS_DD9XSULGPaKamdDZees-U92YJs82NrSKFJqjjheSzvJHiEzRN0sxLkSPtlEiMYBIBuawoGu9Kkn6LMk5QZhkvybbraW2wuv_pBbcCWzpHOnp8rcuUhp6eUYTZBROS9P0hb6JkoR0GxvwT3NozMnMLXhBf9NOUZFCwpl-hHs1q8emIbDt69pNRPEqnehBa0GR5Cgx5f0fxF7YgagBNaTeUT8a_r8Zj_3LWs.z0J6AQ3YQ3JM-9xxTvt1Aw; accessToken=eyJraWQiOiJwM2JKWGgwR1l1bzlHRTdrTDZzdU90SE5HQUVIVjVKRTlFR2VRRHJcL0JHTT0iLCJhbGciOiJSUzI1NiJ9.eyJzdWIiOiI0ZGVkNmIzNi03MmFiLTRlODgtYjMzMi1iMGNiNDBhNWQwM2MiLCJldmVudF9pZCI6ImNlYzljZTllLTQ1MGItNDg1Yi04YmRkLWQ3MjJhNDEwZTVkZCIsInRva2VuX3VzZSI6ImFjY2VzcyIsInNjb3BlIjoiYXdzLmNvZ25pdG8uc2lnbmluLnVzZXIuYWRtaW4iLCJhdXRoX3RpbWUiOjE1ODkzNzY3MzQsImlzcyI6Imh0dHBzOlwvXC9jb2duaXRvLWlkcC51cy1lYXN0LTEuYW1hem9uYXdzLmNvbVwvdXMtZWFzdC0xX0xnUXN1Qm1mNyIsImV4cCI6MTU4OTkwMjYzMSwiaWF0IjoxNTg5ODk5MDMxLCJqdGkiOiI2YzE1ZTNmMS1lNWYxLTQ2YzQtOTQwYS1jMWNjMjc2ZTY4OWYiLCJjbGllbnRfaWQiOiIxanBzaWY4MHJybW40bjFjbm81ZHFvbWMxNyIsInVzZXJuYW1lIjoiYXZlbnVlX3JvZG9scGhvQGxpdmUuZGUifQ.JTApuiys6s_0BM5lPpikzqrNmwWiPNvmFFePR7fEbRdcrp8zaPbr6YvJ6k9c10AqfEP63ti3GwDtqoGgMOvPE7jRgpANradsloaKsdw8KyIAveTccDqUnkaU3Eym-qT1_pb6qK5Yurart1Gw7VDZIRz4n8PDgbP26v62f1zRSkdcQUOCMyESUsWWxwG1KaxDvSa3d_vjl3h2HYguNUxIHXHfJTqMMBPRJ1xDwwRSaB4Qr7nkOt9EA7-G0PCezRaIxgRSChPTtHFVVuOscAmBbEAFcuR3v_wb703OuwpJ7hTiQVJX9Dzr_gjFvP0v0R4ksRRwF--gzddlH9flGoBP6g; idToken=eyJraWQiOiJrV0huWFNOWUVXcVJJXC9pNUowVk9BZUJ1SmdmTmJtRXNmQVU5RlkwSjN4Yz0iLCJhbGciOiJSUzI1NiJ9.eyJzdWIiOiI0ZGVkNmIzNi03MmFiLTRlODgtYjMzMi1iMGNiNDBhNWQwM2MiLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiaXNzIjoiaHR0cHM6XC9cL2NvZ25pdG8taWRwLnVzLWVhc3QtMS5hbWF6b25hd3MuY29tXC91cy1lYXN0LTFfTGdRc3VCbWY3IiwicGhvbmVfbnVtYmVyX3ZlcmlmaWVkIjp0cnVlLCJjb2duaXRvOnVzZXJuYW1lIjoiYXZlbnVlX3JvZG9scGhvQGxpdmUuZGUiLCJwcmVmZXJyZWRfdXNlcm5hbWUiOiJyb2RvbHBob0BsaXZlLmRlIiwiYXVkIjoiMWpwc2lmODBycm1uNG4xY25vNWRxb21jMTciLCJldmVudF9pZCI6ImNlYzljZTllLTQ1MGItNDg1Yi04YmRkLWQ3MjJhNDEwZTVkZCIsInRva2VuX3VzZSI6ImlkIiwiYXV0aF90aW1lIjoxNTg5Mzc2NzM0LCJwaG9uZV9udW1iZXIiOiIrNTUxMTk3NTc3ODQ5MCIsImN1c3RvbTpjb25maXJtZWQiOiIxIiwiZXhwIjoxNTg5OTAyNjMxLCJpYXQiOjE1ODk4OTkwMzEsImVtYWlsIjoicm9kb2xwaG9AbGl2ZS5kZSJ9.njXvQPxHb-FmUIigacPqAaCs8OaZMCyDLIM9yPPX0yPM9eLtr8k2GSYOWXaoAwTYArbg3Ax5OKTB1PEGBKL_2j4UNDW3eHeOZy_bWa4NXGK4l_iENb7jmyvOe3fYIBv_dSTSOQMDacedMLV0uY5KgEWelRjh243BMJ6umA4p5PM4XnEWLZ7OCxGWOKT5hQFHv0HxgfMoqLfVGDT9G-y_EM_jAqBICkXnC2mj6lizBlhNUoUs23gsmVBnQ3Gx_kY-ewC3Q9ADlBgDnyUx-mUFTQesSYgmHNzgdQIpVmIX3r_9pSrxnbgMWZlK5CQ15XPfr1Vkng5vx0jQBKvL3biPxQ'
          },
        );

        if (res.statusCode == 200) {
          var jsonResponse = convert.jsonDecode(res.body);
          String _secret = jsonResponse['secret_code'];
          setState(() => secret = _secret);

          String _token = OTP.generateTOTPCodeString(secret, DateTime.now().millisecondsSinceEpoch,
              isGoogle: true);
          setState(() => token = _token);
        } else {
          throw res.reasonPhrase;
        }
      } catch (err) {
        _showSnackBar(err);
      }
    } catch (err) {
      _showSnackBar(err.message);
    }
  }

  void _checkBiometrics() async {
    try {
      bool canCheckBiometrics = await auth.canCheckBiometrics;
      _showSnackBar('Can check biometrics: $canCheckBiometrics');
    } catch (e) {
      print(e);
    }
    if (!mounted) return;
  }
}
