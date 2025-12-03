# Security Policy

## Supported Versions

We release patches for security vulnerabilities in the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 0.0.x   | :white_check_mark: |

## Reporting a Vulnerability

We take the security of IP Camera Streaming Platform seriously. If you believe you have found a security vulnerability, please report it to us as described below.

### Please Do Not

- **Do not** open a public GitHub issue for security vulnerabilities
- **Do not** disclose the vulnerability publicly until it has been addressed

### Please Do

1. **Email us directly** at [INSERT SECURITY EMAIL] with:
   - A description of the vulnerability
   - Steps to reproduce the issue
   - Potential impact of the vulnerability
   - Any suggested fixes (if available)

2. **Allow time for response**:
   - We will acknowledge receipt within 48 hours
   - We will provide a detailed response within 7 days
   - We will work with you to understand and address the issue

3. **Coordinate disclosure**:
   - We will notify you when the vulnerability is fixed
   - We will credit you in the security advisory (unless you prefer to remain anonymous)
   - We will coordinate the public disclosure timing with you

## Security Best Practices for Users

### Network Security

- **Use secure networks**: Avoid streaming over public WiFi without VPN
- **Enable RTSP authentication**: Set strong passwords for RTSP access
- **Firewall configuration**: Only expose necessary ports
- **Use HTTPS/TLS**: When streaming to cloud services, ensure encrypted connections

### Credential Management

- **Strong passwords**: Use unique, complex passwords for RTMP stream keys
- **Rotate credentials**: Regularly update stream keys and passwords
- **Secure storage**: The app uses platform-specific secure storage (Keychain/EncryptedSharedPreferences)
- **Never share credentials**: Don't commit credentials to version control

### Device Security

- **Keep updated**: Install the latest app and OS updates
- **App permissions**: Only grant necessary permissions (camera, microphone, network)
- **Physical security**: Secure your device when streaming
- **Review access**: Regularly check which services have access to your streams

### Privacy Considerations

- **Camera awareness**: Be mindful of what your camera captures
- **Audio privacy**: Disable audio if not needed
- **Network visibility**: Understand who can access your RTSP stream on local network
- **Cloud streaming**: Review privacy policies of streaming platforms (YouTube, Twitch)

## Known Security Considerations

### RTSP Protocol

- RTSP basic authentication is not encrypted by default
- Consider using VPN or SSH tunneling for remote access
- Local network streaming is generally safe behind a firewall

### RTMP Protocol

- RTMP uses TCP and can be encrypted (RTMPS)
- Stream keys should be treated as passwords
- Ensure streaming platforms use secure connections

### Third-Party Dependencies

We regularly audit our dependencies for known vulnerabilities:

- **Live555**: LGPL RTSP library (monitored for CVEs)
- **librtmp**: LGPL RTMP library (monitored for CVEs)
- **libjpeg-turbo**: Image compression library
- **Android/iOS SDKs**: Platform-provided frameworks

## Security Update Process

1. **Vulnerability identified**: Through reports or monitoring
2. **Assessment**: Evaluate severity and impact
3. **Fix development**: Create and test patch
4. **Security advisory**: Publish CVE if applicable
5. **Release**: Deploy fix in new version
6. **Notification**: Inform users via GitHub and release notes

## Vulnerability Disclosure Timeline

- **Day 0**: Vulnerability reported
- **Day 1-2**: Acknowledgment sent to reporter
- **Day 3-7**: Initial assessment and response
- **Day 8-30**: Fix development and testing
- **Day 31-60**: Coordinated disclosure and release
- **Day 61+**: Public disclosure if not yet released

## Security Hall of Fame

We recognize and thank security researchers who responsibly disclose vulnerabilities:

<!-- List will be populated as vulnerabilities are reported and fixed -->

## Contact

For security concerns, contact:
- **Email**: [INSERT SECURITY EMAIL]
- **PGP Key**: [INSERT PGP KEY FINGERPRINT] (optional)

For general questions, use [GitHub Discussions](https://github.com/ORIGINAL_OWNER/ip-camera-streaming/discussions).

## Additional Resources

- [OWASP Mobile Security Project](https://owasp.org/www-project-mobile-security/)
- [Android Security Best Practices](https://developer.android.com/topic/security/best-practices)
- [iOS Security Guide](https://support.apple.com/guide/security/welcome/web)

---

**Last Updated**: December 2024
