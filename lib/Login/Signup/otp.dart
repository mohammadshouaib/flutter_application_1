import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/Login/Signup/changepass.dart';
import 'package:flutter_application_1/Services/forgot_password_service.dart'; // Import your service


class VerificationScreen extends StatefulWidget {
  final TextEditingController emailController ;
  const VerificationScreen({super.key, required this.emailController});

  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LogoWithTitle(
        title: 'Verification',
        subText: "Email Verification code has been sent",
        children: [
          Text(widget.emailController.text),
          SizedBox(height: MediaQuery.of(context).size.height * 0.04),
          // OTP Form
          OtpForm(emailController: widget.emailController,),
        ],
      ),
    );
  }
}

class OtpForm extends StatefulWidget {
  final TextEditingController emailController ;
  const OtpForm({super.key, required this.emailController});

  @override
  _OtpFormState createState() => _OtpFormState();
}

class _OtpFormState extends State<OtpForm> {
  final _formKey = GlobalKey<FormState>();
  final ForgotPasswordService forgotPasswordService = ForgotPasswordService();
  final List<TextInputFormatter> otpTextInputFormatters = [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(1),
  ];
  
  late FocusNode _pin1Node;
  late FocusNode _pin2Node;
  late FocusNode _pin3Node;
  late FocusNode _pin4Node;
  late FocusNode _pin5Node;
  late FocusNode _pin6Node;
  late FocusNode _pin7Node;

  String otp1 = "", otp2 = "", otp3 = "", otp4 = "", otp5 = "", otp6 = "";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pin1Node = FocusNode();
    _pin2Node = FocusNode();
    _pin3Node = FocusNode();
    _pin4Node = FocusNode();
    _pin5Node = FocusNode();
    _pin6Node = FocusNode();
    _pin7Node = FocusNode();
  }

  @override
  void dispose() {
    super.dispose();
    _pin1Node.dispose();
    _pin2Node.dispose();
    _pin3Node.dispose();
    _pin4Node.dispose();
    _pin5Node.dispose();
    _pin6Node.dispose();
    _pin7Node.dispose();
  }

  Future<void> _verifyOtp() async {
    String otp = otp1 + otp2 + otp3 + otp4 + otp5 + otp6;
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the complete OTP")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      bool isVerified = await forgotPasswordService.verifyOtp(widget.emailController.text, otp);
      if (isVerified) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChangePasswordScreen(emailController: widget.emailController)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid OTP, please try again")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
Widget build(BuildContext context) {
  return Form(
    key: _formKey,
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: OtpTextFormField(
                focusNode: _pin1Node,
                onChanged: (value) {
                  otp1 = value;
                  if (value.length == 1) _pin2Node.requestFocus();
                },
                autofocus: true,
              ),
            ),
            const SizedBox(width: 8.0),
            Flexible(
              child: OtpTextFormField(
                focusNode: _pin2Node,
                onChanged: (value) {
                  otp2 = value;
                  if (value.length == 1) _pin3Node.requestFocus();
                },
              ),
            ),
            const SizedBox(width: 8.0),
            Flexible(
              child: OtpTextFormField(
                focusNode: _pin3Node,
                onChanged: (value) {
                  otp3 = value;
                  if (value.length == 1) _pin4Node.requestFocus();
                },
              ),
            ),
            const SizedBox(width: 8.0),
            Flexible(
              child: OtpTextFormField(
                focusNode: _pin4Node,
                onChanged: (value) {
                  otp4 = value;
                  if (value.length == 1) _pin5Node.requestFocus();
                },
              ),
            ),
            const SizedBox(width: 8.0),
            Flexible(
              child: OtpTextFormField(
                focusNode: _pin5Node,
                onChanged: (value) {
                  otp5 = value;
                  if (value.length == 1) _pin6Node.requestFocus();
                },
              ),
            ),
            const SizedBox(width: 8.0),
            Flexible(
              child: OtpTextFormField(
                focusNode: _pin6Node,
                onChanged: (value) {
                  otp6 = value;
                  if (value.length == 1) _pin7Node.requestFocus();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 24.0),
        _isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _verifyOtp,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFF00BF6D),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: const StadiumBorder(),
                ),
                child: const Text("Next"),
              ),
      ],
    ),
  );
}
}

const InputDecoration otpInputDecoration = InputDecoration(
  filled: false,
  border: UnderlineInputBorder(),
  hintText: "",
);

class OtpTextFormField extends StatelessWidget {
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final FormFieldSetter<String>? onSaved;
  final bool autofocus;

  const OtpTextFormField(
      {super.key,
      this.focusNode,
      this.onChanged,
      this.onSaved,
      this.autofocus = false});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      autovalidateMode: AutovalidateMode.onUserInteraction,
      focusNode: focusNode,
      onChanged: onChanged,
      onSaved: onSaved,
      autofocus: autofocus,
      obscureText: true,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(1),
      ],
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      style: Theme.of(context).textTheme.headlineSmall,
      decoration: otpInputDecoration,
    );
  }
}

class LogoWithTitle extends StatelessWidget {
  final String title, subText;
  final List<Widget> children;

  const LogoWithTitle(
      {super.key,
      required this.title,
      this.subText = '',
      required this.children});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              SizedBox(height: constraints.maxHeight * 0.1),
              Image.network(
                "https://i.postimg.cc/nz0YBQcH/Logo-light.png",
                height: 100,
              ),
              SizedBox(
                height: constraints.maxHeight * 0.1,
                width: double.infinity,
              ),
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall!
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  subText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    height: 1.5,
                    color: Theme.of(context)
                        .textTheme
                        .bodyLarge!
                        .color!
                        .withOpacity(0.64),
                  ),
                ),
              ),
              ...children,
            ],
          ),
        );
      }),
    );
  }
}
