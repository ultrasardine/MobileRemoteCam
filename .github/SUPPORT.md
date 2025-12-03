# Support

Thank you for using IP Camera Streaming Platform! This document provides information on how to get help.

## Documentation

- **README**: [README.md](../README.md) - Project overview and quick start
- **Contributing Guide**: [CONTRIBUTING.md](../CONTRIBUTING.md) - How to contribute
- **Roadmap**: [ROADMAP.md](../ROADMAP.md) - Future plans and milestones
- **Changelog**: [CHANGELOG.md](../CHANGELOG.md) - Version history

## Getting Help

### Before Asking for Help

1. **Check the documentation** - Most common questions are answered in the README
2. **Search existing issues** - Your question may have already been answered
3. **Review closed issues** - Solutions might be in resolved issues

### Where to Get Help

#### GitHub Discussions (Recommended)
For general questions, ideas, and community support:
- [Start a Discussion](https://github.com/ORIGINAL_OWNER/ip-camera-streaming/discussions)

**Discussion Categories:**
- **Q&A**: Ask questions about usage, configuration, or troubleshooting
- **Ideas**: Share feature suggestions and discuss improvements
- **Show and Tell**: Share your streaming setups and use cases
- **General**: Everything else

#### GitHub Issues
For bug reports and feature requests:
- [Report a Bug](https://github.com/ORIGINAL_OWNER/ip-camera-streaming/issues/new?template=bug_report.md)
- [Request a Feature](https://github.com/ORIGINAL_OWNER/ip-camera-streaming/issues/new?template=feature_request.md)

**Please use issues only for:**
- Confirmed bugs
- Specific feature requests
- Documentation improvements

**Do NOT use issues for:**
- General questions (use Discussions instead)
- Support requests (use Discussions instead)
- Security vulnerabilities (see [SECURITY.md](../SECURITY.md))

## Common Questions

### Installation & Setup

**Q: The app won't install on my device**
- Ensure your device meets minimum requirements (Android 11+)
- Enable "Install from Unknown Sources" for APK installation
- Check available storage space

**Q: Camera permission denied**
- Go to Settings → Apps → IP Camera → Permissions
- Enable Camera and Microphone permissions

### Streaming Issues

**Q: RTSP stream not working in OBS**
- Verify the stream URL is correct (check IP address)
- Ensure both devices are on the same network
- Check firewall settings on your computer
- Try disabling hardware decoding in OBS

**Q: RTMP stream fails to connect**
- Verify stream URL and key are correct
- Check internet connection stability
- Ensure streaming service is accepting connections
- Try reducing bitrate or resolution

**Q: Poor video quality or lag**
- Reduce resolution or bitrate
- Check network bandwidth
- Close other apps using camera/network
- Ensure device isn't overheating

### Development

**Q: Build fails with Gradle errors**
- Ensure you have JDK 17 installed
- Run `./gradlew clean build`
- Check that Android SDK is properly configured
- Review [CONTRIBUTING.md](../CONTRIBUTING.md) for setup instructions

**Q: How can I contribute?**
- Read [CONTRIBUTING.md](../CONTRIBUTING.md)
- Look for issues labeled `good first issue`
- Join discussions to understand the project better

## Response Times

This is an open source project maintained by volunteers. Response times vary:

- **Critical bugs**: We aim to respond within 48 hours
- **Feature requests**: May take several days to weeks
- **General questions**: Community members usually respond within 24-48 hours

## Community Guidelines

When seeking support:
- **Be respectful** - Follow our [Code of Conduct](../CODE_OF_CONDUCT.md)
- **Be specific** - Provide details, logs, and steps to reproduce
- **Be patient** - Maintainers are volunteers
- **Give back** - Help others when you can

## Security Issues

**Do NOT post security vulnerabilities publicly.**

Report security issues privately by following the instructions in [SECURITY.md](../SECURITY.md).

## Commercial Support

Currently, we do not offer commercial support. For enterprise needs, consider:
- Hiring a consultant familiar with the project
- Sponsoring development of specific features
- Contributing to the project to improve it for everyone

## Additional Resources

- **Android Camera2 API**: https://developer.android.com/training/camera2
- **RTSP Protocol**: https://en.wikipedia.org/wiki/Real_Time_Streaming_Protocol
- **RTMP Protocol**: https://en.wikipedia.org/wiki/Real-Time_Messaging_Protocol
- **OBS Studio**: https://obsproject.com/wiki/

---

**Still need help?** [Start a discussion](https://github.com/ORIGINAL_OWNER/ip-camera-streaming/discussions) and the community will assist you!
