import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:libas_app/src/common/constant/app_color.dart';
import 'package:libas_app/src/common/services/auth_service.dart';
import 'package:provider/provider.dart';

void showPhoneAuthBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
    ),
    builder: (_) => Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16.w,
          right: 16.w,
          top: 24.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with Done button
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Sign In / Create Account',
                        style: GoogleFonts.poppins(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Enter your phone number to continue',
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          color: AppColors.greyColor,
                        ),
                      ),
                    ],
                  ),
                ),
                // Done button
                TextButton(
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Done',
                    style: GoogleFonts.poppins(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),
            
            // Phone Auth Form
            Expanded(
              child: SingleChildScrollView(
                child: PhoneAuthForm(),
              ),
            ),
            
            SizedBox(height: 16.h),
          ],
        ),
      ),
    ),
  );
}

class PhoneAuthForm extends StatefulWidget {
  @override
  _PhoneAuthFormState createState() => _PhoneAuthFormState();
}

class _PhoneAuthFormState extends State<PhoneAuthForm> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  
  bool _isLoading = false;
  bool _otpSent = false;
  bool _isNewUser = false;
  String _currentPhone = '';
  int _resendTimer = 0;
  bool _canResend = true;
  String _preferredMethod = 'email'; // Default to email

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    if (_resendTimer > 0) {
      Future.delayed(Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _resendTimer--;
            _canResend = _resendTimer == 0;
          });
          _startResendTimer();
        }
      });
    }
  }

  Future<void> _sendOTP() async {
    final phoneNumber = _phoneController.text.trim();
    if (phoneNumber.isEmpty) {
      _showError('Please enter your phone number');
      return;
    }

    if (phoneNumber.length < 10) {
      _showError('Please enter a valid phone number');
      return;
    }

    // Validate email if email method is selected
    if (_preferredMethod == 'email' && _emailController.text.trim().isEmpty) {
      _showError('Email is required for email OTP delivery. Please enter your email or switch to SMS.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = context.read<AuthService>();
      final result = await authService.sendOTP(
        phoneNumber, 
        email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        preferredMethod: _preferredMethod,
      );

      if (result['success']) {
        setState(() {
          _otpSent = true;
          _currentPhone = phoneNumber;
          _resendTimer = 60;
          _canResend = false;
        });
        _startResendTimer();
        
        // Check if user exists
        final userCheck = await authService.checkUserExists(phoneNumber);
        if (userCheck['success']) {
          setState(() {
            _isNewUser = !userCheck['data']['exists'];
          });
        }

        _showSuccess('OTP sent successfully via ${_preferredMethod.toUpperCase()}!');
      } else {
        _showError(result['error']);
      }
    } catch (e) {
      _showError('Failed to send OTP. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyOTP() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      _showError('Please enter the OTP');
      return;
    }

    if (otp.length != 6) {
      _showError('Please enter a valid 6-digit OTP');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = context.read<AuthService>();
      final result = await authService.verifyOTP(
        _currentPhone,
        otp,
        name: _isNewUser ? _nameController.text.trim() : null,
        email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
      );

      if (result['success']) {
        Navigator.of(context).pop();
        _showSuccess(result['isNewUser'] ? 'Account created successfully!' : 'Login successful!');
      } else {
        _showError(result['error']);
      }
    } catch (e) {
      _showError('Failed to verify OTP. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resendOTP() async {
    if (!_canResend) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = context.read<AuthService>();
      final result = await authService.resendOTP(_currentPhone, email: _emailController.text.trim());

      if (result['success']) {
        setState(() {
          _resendTimer = 60;
          _canResend = false;
        });
        _startResendTimer();
        _showSuccess('OTP resent successfully!');
      } else {
        _showError(result['error']);
      }
    } catch (e) {
      _showError('Failed to resend OTP. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Phone Number Input
        if (!_otpSent) ...[
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) {
              FocusScope.of(context).nextFocus();
            },
            decoration: InputDecoration(
              labelText: 'Phone Number',
              hintText: 'Enter your phone number',
              prefixIcon: Icon(Icons.phone, color: AppColors.primaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          
          // Email Input (Optional)
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              FocusScope.of(context).unfocus();
            },
            decoration: InputDecoration(
              labelText: 'Email (Optional)',
              hintText: 'Enter your email for OTP backup',
              prefixIcon: Icon(Icons.email, color: AppColors.greyColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          
          // OTP Method Selection
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.greyColor.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OTP Delivery Method',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: Text(
                          'Email',
                          style: GoogleFonts.poppins(fontSize: 14.sp),
                        ),
                        subtitle: Text(
                          'Receive OTP via email',
                          style: GoogleFonts.poppins(
                            fontSize: 12.sp,
                            color: AppColors.greyColor,
                          ),
                        ),
                        value: 'email',
                        groupValue: _preferredMethod,
                        onChanged: (value) {
                          setState(() {
                            _preferredMethod = value!;
                          });
                        },
                        activeColor: AppColors.primaryColor,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: Text(
                          'SMS',
                          style: GoogleFonts.poppins(fontSize: 14.sp),
                        ),
                        subtitle: Text(
                          'Receive OTP via SMS',
                          style: GoogleFonts.poppins(
                            fontSize: 12.sp,
                            color: AppColors.greyColor,
                          ),
                        ),
                        value: 'sms',
                        groupValue: _preferredMethod,
                        onChanged: (value) {
                          setState(() {
                            _preferredMethod = value!;
                          });
                        },
                        activeColor: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          
          // Send OTP Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _sendOTP,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  : Text(
                      'Send OTP',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ] else ...[
          // OTP Input
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            maxLength: 6,
            onSubmitted: (_) {
              FocusScope.of(context).unfocus();
            },
            decoration: InputDecoration(
              labelText: 'OTP',
              hintText: 'Enter 6-digit OTP',
              prefixIcon: Icon(Icons.lock, color: AppColors.primaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              counterText: '',
            ),
          ),
          SizedBox(height: 16.h),
          
          // Name Input (for new users)
          if (_isNewUser) ...[
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                FocusScope.of(context).unfocus();
              },
              decoration: InputDecoration(
                labelText: 'Full Name',
                hintText: 'Enter your full name',
                prefixIcon: Icon(Icons.person, color: AppColors.primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
          ],
          
          // Resend OTP
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Didn't receive OTP? ",
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  color: AppColors.greyColor,
                ),
              ),
              GestureDetector(
                onTap: _canResend ? _resendOTP : null,
                child: Text(
                  _canResend ? 'Resend' : 'Resend in $_resendTimer seconds',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    color: _canResend ? AppColors.primaryColor : AppColors.greyColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          
          // Verify OTP Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _verifyOTP,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  : Text(
                      'Verify OTP',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          
          SizedBox(height: 16.h),
          
          // Back to Phone Input
          TextButton(
            onPressed: () {
              setState(() {
                _otpSent = false;
                _otpController.clear();
                _nameController.clear();
                _resendTimer = 0;
                _canResend = true;
              });
            },
            child: Text(
              'Change Phone Number',
              style: GoogleFonts.poppins(
                color: AppColors.primaryColor,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
} 