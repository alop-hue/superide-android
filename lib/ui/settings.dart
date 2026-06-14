import 'dart:convert';
import 'dart:io';
import 'package:code_forge/code_forge.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:xterm/xterm.dart';
import 'package:roxum/utils/constants.dart';
import '../bloc/ui_bloc/ui_bloc.dart';
import 'downloads.dart';
import '../utils/functions.dart';
import '../utils/languages.dart';
import '../utils/themes.dart';
import 'widgets.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  late final Terminal terminal;
  late final SshKeygen sshKeygen;
  final apiController = TextEditingController();
  final modelNameController = TextEditingController(), modelIdController = TextEditingController();
  final scrollController = ScrollController(), terminalThemeScroll = ScrollController();
  final sshUrlController = TextEditingController(), sshServerNameController = TextEditingController();
  final sshPasswordController = TextEditingController();
  final themeScroll = ScrollController(), fontScroll = ScrollController();
  final _formKey = GlobalKey<FormState>(), _sshFormKey = GlobalKey<FormState>(), _sshUpdationKey = GlobalKey<FormState>();
  final _ggufKey = GlobalKey<FormState>();
  bool? _isGeneratedKey;
  int sshStackIndex = 0;
  final List<Map<String, dynamic>> _ggufModels = [
    {
      'name': 'Qwen2.5-Coder-3B',
      'url': 'https://huggingface.co/bartowski/Qwen2.5-Coder-3B-Instruct-GGUF/resolve/main/Qwen2.5-Coder-3B-Instruct-Q6_K.gguf',
      'filename': 'Qwen2.5-Coder-3B-Instruct-Q6_K.gguf',
      'param-size': 3,
      'quant': 'Q6_K',
      'image-url': 'https://cdn-avatars.huggingface.co/v1/production/uploads/620760a26e3b7210c2ff1943/-s1gyJfvbE1RgO5iBeNOi.png'
    },
    {
      'name': 'Phi-3.5-mini',
      'url': 'https://huggingface.co/bartowski/Phi-3.5-mini-instruct-GGUF/resolve/main/Phi-3.5-mini-instruct-Q6_K.gguf',
      'filename': 'Phi-3.5-mini-instruct-Q6_K.gguf',
      'param-size': 3.8,
      'quant': 'Q6_K',
      'image-url': 'https://cdn-avatars.huggingface.co/v1/production/uploads/1583646260758-5e64858c87403103f9f1055d.png'
    },
    {
      'name': 'Phi-3-mini-4k',
      'url': 'https://huggingface.co/bartowski/Phi-3-mini-4k-instruct-GGUF/resolve/main/Phi-3-mini-4k-instruct-Q6_K.gguf',
      'filename': 'Phi-3-mini-4k-instruct-Q6_K.gguf',
      'param-size': 3.8,
      'quant': 'Q6_K',
      'image-url': 'https://cdn-avatars.huggingface.co/v1/production/uploads/1583646260758-5e64858c87403103f9f1055d.png'
    },
    {
      'name': 'Qwen2.5.1-Coder-1.5B',
      'url': 'https://huggingface.co/bartowski/Qwen2.5.1-Coder-1.5B-Instruct-GGUF/resolve/main/Qwen2.5.1-Coder-1.5B-Instruct-Q6_K.gguf',
      'filename': 'Qwen2.5.1-Coder-1.5B-Instruct-Q6_K.gguf',
      'param-size': 1.5,
      'quant': 'Q6_K',
      'image-url': 'https://cdn-avatars.huggingface.co/v1/production/uploads/620760a26e3b7210c2ff1943/-s1gyJfvbE1RgO5iBeNOi.png'
    },
    { 
      'name': 'deepseek-coder-1.3B',
      'url': 'https://huggingface.co/bartowski/deepseek-coder-1.3B-kexer-GGUF/resolve/main/deepseek-coder-1.3B-kexer-Q6_K.gguf',
      'filename': 'deepseek-coder-1.3B-kexer-Q6_K.gguf',
      'param-size': 1.3,
      'quant': 'Q6_K',
      'image-url': 'https://cdn-avatars.huggingface.co/v1/production/uploads/6538815d1bdb3c40db94fbfa/xMBly9PUMphrFVMxLX4kq.png'
    },
    {
      'name': 'Granite-Code-3B',
      'url': 'https://huggingface.co/unsloth/granite-4.1-3b-GGUF/resolve/main/granite-4.1-3b-Q6_K.gguf',
      'filename': 'granite-code-3b-instruct-Q6_K.gguf',
      'param-size': 3,
      'quant': 'Q6_K',
      'image-url': 'https://cdn-avatars.huggingface.co/v1/production/uploads/6602b217c774ff142b1493ef/Tvie7jwa9ggFjrQ5ty_Br.webp'
    },
    {
      'name': 'Gemma-2-2B',
      'url': 'https://huggingface.co/bartowski/gemma-2-2b-it-GGUF/resolve/main/gemma-2-2b-it-Q6_K.gguf',
      'filename': 'gemma-2-2b-it-Q6_K.gguf',
      'param-size': 2,
      'quant': 'Q6_K',
      'image-url': 'https://cdn-avatars.huggingface.co/v1/production/uploads/5dd96eb166059660ed1ee413/WtA3YYitedOr9n02eHfJe.png'
    },
    {
      'name': 'CodeLlama-7B',
      'url': 'https://huggingface.co/TheBloke/CodeLlama-7B-Instruct-GGUF/resolve/main/codellama-7b-instruct.Q4_K_M.gguf',
      'filename': 'CodeLlama-7B-Instruct-Q4_K_M.gguf',
      'param-size': 7,
      'quant': 'Q4_K_M',
      'image-url': 'https://cdn-avatars.huggingface.co/v1/production/uploads/646cf8084eefb026fb8fd8bc/oCTqufkdTkjyGodsx1vo1.png'
    }
  ];
  final String demoCode =
'''
#include <stdio.h>

int main() {
    int n = 10, t1 = 0, t2 = 1, nextTerm;
    printf("Fibonacci Series: ");
    for (int i = 1; i <= n; ++i) {
        printf("%d ", t1);
        nextTerm = t1 + t2;
        t1 = t2;
        t2 = nextTerm;
    }
    return 0;
}''';
  final List<String> models = [
    "Gemini",
    "Claude",
    "OpenAI",
    "Grok",
    "DeepSeek",
    "Gorq",
    "TogetherAI",
    "Perplexity",
    "OpenRouter",
    "FireWorks",
    "Custom",
    "LocalLlama"
    ];

  @override
  void initState() {
    super.initState();

    sshKeygen = SshKeygen(
      comment: "user@roxum-IDE",
    );

    if(SshKeygen.publicKeyFilelocation.existsSync() && SshKeygen.privateKeyFilelocation.existsSync()){
      _isGeneratedKey = true;
    }
    terminal = Terminal(platform: TerminalTargetPlatform.android);
    _seedTerminalPreview();
    _initializeCopilotForSettingsWhenDisabled();
  }

  void _seedTerminalPreview() {
    terminal.write(
      '\x1b[1;32mroxum\x1b[0m@\x1b[1;34mdevice\x1b[0m:\x1b[36m~/workspace\x1b[0m\$ '
      'git status\r\n',
    );
    terminal.write('On branch playstore-version\r\n');
    terminal.write('nothing to commit, working tree clean\r\n\r\n');
    terminal.write('status: \x1b[32mOK\x1b[0m  ');
    terminal.write('warn: \x1b[33m2\x1b[0m  ');
    terminal.write('errors: \x1b[31m0\x1b[0m\r\n');
  }

  Future<void> _saveCodeForgeConfig(Map<String, dynamic> codeForgeConfig) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('codeForgeConfig', jsonEncode(codeForgeConfig));
    if (!mounted) return;
    context.read<ConfigBloc>().add(ChangeConfigEvent(codeForgeConfig));
  }

  Future<void> _initializeCopilotForSettingsWhenDisabled() async {
    final isCopilotEnabled = await isCopilotEnabledPref();
    if (isCopilotEnabled || !mounted) {
      return;
    }

    if (!Directory('$extensionDir/copilot-language-server').existsSync()) {
      return;
    }

    final copilotBloc = context.read<CopilotBloc>();
    if (copilotBloc.state.isInitialized || copilotBloc.state.status == CopilotStatus.initializing) {
      return;
    }

    copilotBloc.add(CopilotInitialize(configPath: filesDir));
  }

  Widget _buildCopilotButton(BuildContext context, CopilotState copilotState, AppThemeState appThemeState) {
    final status = copilotState.status;
    String buttonText;
    Color buttonColor;
    VoidCallback? onPressed;
    bool showLoading = false;

    switch (status) {
      case CopilotStatus.notInitialized:
      case CopilotStatus.notSignedIn:
        buttonText = "Sign in with GitHub Copilot";
        buttonColor = Colors.lightBlue;
        onPressed = () => _startCopilotSignIn(context, appThemeState);
        break;
      case CopilotStatus.initializing:
      case CopilotStatus.signingIn:
        buttonText = "Connecting...";
        buttonColor = Colors.grey;
        showLoading = true;
        onPressed = null;
        break;
      case CopilotStatus.signedIn:
        buttonText = copilotState.user != null
            ? "Signed in as ${copilotState.user}"
            : "GitHub Copilot Connected";
        buttonColor = Colors.green;
        onPressed = () => _showCopilotSettings(context, copilotState, appThemeState);
        break;
      case CopilotStatus.notAuthorized:
        buttonText = "Copilot Not Authorized";
        buttonColor = Colors.orange;
        onPressed = () => _showNotAuthorizedDialog(context, appThemeState);
        break;
      case CopilotStatus.error:
        buttonText = "Connection Error";
        buttonColor = Colors.red;
        onPressed = () => _startCopilotSignIn(context, appThemeState);
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 15),
      child: SizedBox(
        width: 280,
        height: 45,
        child: ElevatedButton(
          onPressed: () => onPressed?.call(),
          style: ButtonStyle(
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            backgroundColor: WidgetStatePropertyAll(buttonColor),
          ),
          child: showLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                spacing: 7.5,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/icons/github-copilot-icon.svg',
                    height: 20,
                    width: 20,
                    colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  ),
                  Flexible(
                    child: Text(
                      buttonText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }

  List<String> _missingCopilotPrerequisites() {
    final missing = <String>[];
    if (!Directory('$extensionDir/copilot-language-server').existsSync()) {
      missing.add('GitHub Copilot extension');
    }
    if (!File('$binDir/node').existsSync()) {
      missing.add('Node runtime');
    }
    return missing;
  }

  void _showCopilotPrerequisiteDialog(
    BuildContext context,
    AppThemeState appThemeState,
    List<String> missing,
  ) {
    final textColor = appThemeState.appTheme.selectScreenCardTextColor;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: appThemeState.appTheme.isDark
            ? const Color(0xff2b2b2b)
            : const Color.fromARGB(255, 240, 240, 240),
          title: Text('Copilot Setup Required', style: TextStyle(color: textColor)),
          content: Text(
            'Before signing in, please install: ${missing.join(' and ')}.\n\nOpen Downloads to install them.',
            style: TextStyle(color: textColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => const DownloadManager(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return SizeTransition(sizeFactor: animation, child: child);
                    },
                  ),
                );
              },
              child: const Text('Open Downloads'),
            ),
          ],
        );
      },
    );
  }

  void _showNodeRuntimeRequiredDialog(
    BuildContext context,
    AppThemeState appThemeState,
  ) {
    final textColor = appThemeState.appTheme.selectScreenCardTextColor;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: appThemeState.appTheme.isDark
            ? const Color(0xff2b2b2b)
            : const Color.fromARGB(255, 240, 240, 240),
          title: Text('Node Runtime Required', style: TextStyle(color: textColor)),
          content: Text(
            'GitHub Copilot sign-in requires the Node.js runtime.\n\nPlease install Node.js from Downloads before continuing.',
            style: TextStyle(color: textColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => const DownloadManager(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return SizeTransition(sizeFactor: animation, child: child);
                    },
                  ),
                );
              },
              child: const Text('Open Downloads'),
            ),
          ],
        );
      },
    );
  }

  void _startCopilotSignIn(BuildContext context, AppThemeState appThemeState) async {
    final missing = _missingCopilotPrerequisites();
    if (missing.isNotEmpty) {
      if (missing.length == 1 && missing.first == 'Node runtime') {
        _showNodeRuntimeRequiredDialog(context, appThemeState);
      } else {
        _showCopilotPrerequisiteDialog(context, appThemeState, missing);
      }
      return;
    }

    final copilotBloc = context.read<CopilotBloc>();

    if (copilotBloc.state.status == CopilotStatus.notInitialized) {
      copilotBloc.add(CopilotInitialize(configPath: filesDir));

      await Future.delayed(const Duration(seconds: 2));
    }

    copilotBloc.add(CopilotSignInInitiate());

    if (context.mounted) {
      _showSignInDialog(context, appThemeState);
    }
  }

  void _showSignInDialog(BuildContext context, AppThemeState appThemeState) {
    final isDark = appThemeState.appTheme.isDark;
    final textColor = appThemeState.appTheme.selectScreenCardTextColor;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return BlocBuilder<CopilotBloc, CopilotState>(
          builder: (context, state) {
            if (state.status == CopilotStatus.signedIn) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 12),
                          Text('Signed in as ${state.user ?? "user"}'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              });
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                width: 340,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [const Color(0xff2b2b2b), const Color(0xff1a1a1a)]
                        : [const Color(0xfffafafa), const Color(0xfff0f0f0)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xff0078d4).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SvgPicture.asset(
                            'assets/icons/github-copilot-icon.svg',
                            height: 28,
                            width: 28,
                            colorFilter: ColorFilter.mode(
                              isDark ? Colors.white : const Color(0xff0078d4),
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'GitHub Copilot',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Sign in to continue',
                                style: TextStyle(
                                  color: textColor.withValues(alpha: 0.6),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: Icon(
                            Icons.close,
                            color: textColor.withValues(alpha: 0.5),
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSignInDialogContent(state, context, appThemeState),
                    const SizedBox(height: 24),
                    if (state.signInPayload != null && state.status != CopilotStatus.signedIn)
                      _buildSignInButton(context, state, isDark),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSignInButton(BuildContext context, CopilotState state, bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: () async {
          final code = state.signInPayload!.userCode;
          if (code != null) {
            await Clipboard.setData(ClipboardData(text: code));
          }

          const url = 'https://github.com/login/device';
          final uri = Uri.parse(url);
          try {
            await launchUrl(uri, mode: LaunchMode.inAppWebView);
          } catch (e) {
            debugPrint('Failed to launch URL: $e');
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff238636),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.open_in_browser, size: 20),
            SizedBox(width: 8),
            Text(
              'Sign in with GitHub',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignInDialogContent(CopilotState state, BuildContext context, AppThemeState appThemeState) {
    final isDark = appThemeState.appTheme.isDark;
    final textColor = appThemeState.appTheme.selectScreenCardTextColor;

    if (state.status == CopilotStatus.signingIn && state.signInPayload == null) {
      return SizedBox(
        height: 120,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDark ? Colors.white : const Color(0xff0078d4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Connecting to GitHub...',
              style: TextStyle(
                color: textColor.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (state.signInPayload != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Your code',
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  state.signInPayload!.userCode ?? '',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 6,
                    fontFamily: 'monospace',
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              final code = state.signInPayload!.userCode;
              if (code != null) {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.check, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text('Code copied!'),
                      ],
                    ),
                    backgroundColor: const Color(0xff238636),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            icon: Icon(
              Icons.copy_rounded,
              size: 18,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            label: Text(
              'Copy code',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xff0078d4).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: isDark ? Colors.lightBlueAccent : const Color(0xff0078d4),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Click the button below to open GitHub.\nPaste the code when prompted.',
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor.withValues(alpha: 0.8),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (state.status == CopilotStatus.error) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              state.error ?? 'An error occurred',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                context.read<CopilotBloc>().add(CopilotSignInInitiate());
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _showCopilotSettings(BuildContext context, CopilotState state, AppThemeState appThemeState) {
    final isDark = appThemeState.appTheme.isDark;
    final textColor = appThemeState.appTheme.selectScreenCardTextColor;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 340,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xff2b2b2b), const Color(0xff1a1a1a)]
                    : [const Color(0xfffafafa), const Color(0xfff0f0f0)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SvgPicture.asset(
                        'assets/icons/github-copilot-icon.svg',
                        height: 28,
                        width: 28,
                        colorFilter: ColorFilter.mode(
                          Colors.green,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GitHub Copilot',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Connected',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: Icon(
                        Icons.close,
                        color: textColor.withValues(alpha: 0.5),
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // User info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xff238636).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Color(0xff238636),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.user ?? 'User',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'GitHub Account',
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                BlocBuilder<CopilotBloc, CopilotState>(
                  builder: (context, copilotState) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                copilotState.isEnabled
                                    ? Icons.auto_awesome
                                    : Icons.auto_awesome_outlined,
                                color: copilotState.isEnabled
                                    ? const Color(0xff238636)
                                    : textColor.withValues(alpha: 0.5),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Enable Copilot',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: copilotState.isEnabled,
                            activeThumbColor: const Color(0xff238636),
                            onChanged: (value) {
                              context.read<CopilotBloc>().add(CopilotSetEnabled(value));
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.read<CopilotBloc>().add(CopilotSignOut());
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              Icon(Icons.logout, color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text('Signed out from Copilot'),
                            ],
                          ),
                          backgroundColor: Colors.grey[700],
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      );
                    },
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Sign Out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNotAuthorizedDialog(BuildContext context, AppThemeState appThemeState) {
    final isDark = appThemeState.appTheme.isDark;
    final textColor = appThemeState.appTheme.selectScreenCardTextColor;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 340,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xff2b2b2b), const Color(0xff1a1a1a)]
                    : [const Color(0xfffafafa), const Color(0xfff0f0f0)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Warning icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  'Not Authorized',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  'Your GitHub account does not have access to GitHub Copilot. Please ensure you have an active Copilot subscription.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.7),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Got it',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _clearModelDialogControllers() {
    apiController.clear();
    modelNameController.clear();
    modelIdController.clear();
  }

  Future<void> _showModelDialog({
    required BuildContext context,
    required AIState aiState,
    required AppThemeState appThemeState,
    String? editingModelId,
    Map<String, dynamic>? existingConfig,
  }) async {
    final isEditing = editingModelId != null && existingConfig != null;
    String? provider = isEditing
        ? (existingConfig['provider']?.toString() ?? existingConfig['apiProvider']?.toString())
        : null;
    String customHttpMethod = isEditing
        ? (existingConfig['httpMethod']?.toString() ?? 'POST')
        : 'POST';
    String customToolCallingMethod = isEditing
        ? (existingConfig['toolCallingMethod']?.toString() ?? 'openAiCompatible')
        : 'openAiCompatible';

    modelNameController.text = isEditing
        ? (existingConfig['modelName']?.toString() ?? existingConfig['model']?.toString() ?? '')
        : '';
    apiController.text = isEditing ? (existingConfig['apiKey']?.toString() ?? '') : '';
    modelIdController.text = isEditing ? editingModelId : '';

    final customUrlController = TextEditingController(
      text: isEditing ? (existingConfig['url']?.toString() ?? '') : '',
    );

    try {
      await showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              final isCustomProvider = provider == 'Custom';
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                backgroundColor: appThemeState.appTheme.isDark
                    ? const Color(0xff181A26)
                    : Colors.white,
                child: Container(
                  width: 400,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: appThemeState.appTheme.isDark
                          ? [const Color(0xff181A26), const Color(0xff1e1f2b)]
                          : [Colors.white, Colors.grey[100]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.smart_toy, color: Colors.lightBlue, size: 30),
                          const SizedBox(width: 10),
                          Text(
                            isEditing ? 'Edit AI model' : 'Create a completion model',
                            style: TextStyle(
                              color: appThemeState.appTheme.selectScreenCardTextColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            DropdownButtonFormField<String>(
                              initialValue: provider,
                              dropdownColor: appThemeState.appTheme.isDark
                                  ? const Color(0xff181A26)
                                  : Colors.white,
                              hint: Text(
                                'Select a Provider',
                                style: TextStyle(
                                  color: appThemeState.appTheme.selectScreenCardTextColor.withAlpha(150),
                                ),
                              ),
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.business, color: Colors.lightBlue),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(
                                    color: Colors.lightBlue,
                                    width: 2,
                                  ),
                                ),
                              ),
                              items: List.generate(
                                models.length,
                                (index) => DropdownMenuItem(
                                  value: models[index],
                                  child: Text(
                                    models[index],
                                    style: TextStyle(
                                      color: appThemeState.appTheme.selectScreenCardTextColor,
                                    ),
                                  ),
                                ),
                              ),
                              onChanged: (val) {
                                setDialogState(() {
                                  provider = val;
                                });
                              },
                              validator: (value) =>
                                  value == null ? 'Select a valid provider' : null,
                            ),
                            const SizedBox(height: 15),
                            TextFormField(
                              style: TextStyle(
                                color: appThemeState.appTheme.selectScreenCardTextColor,
                              ),
                              controller: modelNameController,
                              cursorColor: Colors.lightBlue,
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.label, color: Colors.lightBlue),
                                hintText: "model name as per the provider's api",
                                hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(
                                    color: Colors.lightBlue,
                                    width: 2,
                                  ),
                                ),
                                labelText: 'Model Name',
                                labelStyle: TextStyle(
                                  color: appThemeState.appTheme.selectScreenCardTextColor.withAlpha(150),
                                  fontSize: 15,
                                ),
                              ),
                              validator: (value) => value == null || value.isEmpty
                                  ? 'Enter a valid model name'
                                  : null,
                            ),
                            const SizedBox(height: 15),
                            TextFormField(
                              style: TextStyle(
                                color: appThemeState.appTheme.selectScreenCardTextColor,
                              ),
                              controller: apiController,
                              cursorColor: Colors.lightBlue,
                              obscureText: true,
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.key, color: Colors.lightBlue),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(
                                    color: Colors.lightBlue,
                                    width: 2,
                                  ),
                                ),
                                labelText: 'API Key',
                                hintText: isCustomProvider
                                    ? 'Optional: Bearer token for the custom endpoint'
                                    : 'API key for the corresponding provider',
                                hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                                labelStyle: TextStyle(
                                  color: appThemeState.appTheme.selectScreenCardTextColor.withAlpha(150),
                                  fontSize: 15,
                                ),
                              ),
                              validator: (value) {
                                if (isCustomProvider) {
                                  return null;
                                }
                                return value == null || value.isEmpty
                                    ? 'Enter a valid API key'
                                    : null;
                              },
                            ),
                            if (isCustomProvider) ...[
                              const SizedBox(height: 15),
                              TextFormField(
                                style: TextStyle(
                                  color: appThemeState.appTheme.selectScreenCardTextColor,
                                ),
                                controller: customUrlController,
                                cursorColor: Colors.lightBlue,
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.link, color: Colors.lightBlue),
                                  labelText: 'Custom Endpoint URL',
                                  hintText: 'https://api.example.com/v1/chat/completions',
                                  hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide(
                                      color: Colors.lightBlue,
                                      width: 2,
                                    ),
                                  ),
                                  labelStyle: TextStyle(
                                    color: appThemeState.appTheme.selectScreenCardTextColor.withAlpha(150),
                                    fontSize: 15,
                                  ),
                                ),
                                validator: (value) {
                                  if (!isCustomProvider) return null;
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Enter a valid endpoint URL';
                                  }
                                  final uri = Uri.tryParse(value.trim());
                                  if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
                                    return 'Enter a valid absolute URL';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 15),
                              DropdownButtonFormField<String>(
                                initialValue: customHttpMethod,
                                dropdownColor: appThemeState.appTheme.isDark
                                    ? const Color(0xff181A26)
                                    : Colors.white,
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.http, color: Colors.lightBlue),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide(
                                      color: Colors.lightBlue,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: 'POST',
                                    child: Text('POST', style: TextStyle(color: appThemeState.appTheme.selectScreenCardTextColor)),
                                  ),
                                  DropdownMenuItem(
                                    value: 'GET',
                                    child: Text('GET', style: TextStyle(color: appThemeState.appTheme.selectScreenCardTextColor)),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value == null) return;
                                  setDialogState(() {
                                    customHttpMethod = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 15),
                              DropdownButtonFormField<String>(
                                initialValue: customToolCallingMethod,
                                dropdownColor: appThemeState.appTheme.isDark
                                    ? const Color(0xff181A26)
                                    : Colors.white,
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.hub_outlined, color: Colors.lightBlue),
                                  labelText: 'Agentic Tool Protocol',
                                  labelStyle: TextStyle(
                                    color: appThemeState.appTheme.selectScreenCardTextColor.withAlpha(150),
                                    fontSize: 15,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide(
                                      color: Colors.lightBlue,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: 'openAiCompatible',
                                    child: Text('OpenAI-compatible', style: TextStyle(color: appThemeState.appTheme.selectScreenCardTextColor)),
                                  ),
                                  DropdownMenuItem(
                                    value: 'anthropicMessages',
                                    child: Text('Anthropic Messages', style: TextStyle(color: appThemeState.appTheme.selectScreenCardTextColor)),
                                  ),
                                  DropdownMenuItem(
                                    value: 'geminiFunctionCalling',
                                    child: Text('Gemini Function Calling', style: TextStyle(color: appThemeState.appTheme.selectScreenCardTextColor)),
                                  ),
                                  DropdownMenuItem(
                                    value: 'none',
                                    child: Text('None (disable agentic tools)', style: TextStyle(color: appThemeState.appTheme.selectScreenCardTextColor)),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value == null) return;
                                  setDialogState(() {
                                    customToolCallingMethod = value;
                                  });
                                },
                              ),
                            ],
                            const SizedBox(height: 15),
                            Divider(color: Colors.lightBlue.withAlpha(100)),
                            const SizedBox(height: 15),
                            TextField(
                              style: TextStyle(
                                color: appThemeState.appTheme.selectScreenCardTextColor,
                              ),
                              controller: modelIdController,
                              cursorColor: Colors.lightBlue,
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.tag, color: Colors.lightBlue),
                                hintText: isEditing
                                    ? 'Nick name used to identify this model'
                                    : 'A unique nick name, leave it empty to generate one',
                                hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(
                                    color: Colors.lightBlue,
                                    width: 2,
                                  ),
                                ),
                                labelText: 'Nick Name (Optional)',
                                labelStyle: TextStyle(
                                  color: appThemeState.appTheme.selectScreenCardTextColor.withAlpha(150),
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            ),
                            child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () async {
                              final formState = _formKey.currentState;
                              if (formState == null || !formState.validate()) {
                                return;
                              }

                              final selectedProvider = provider;
                              if (selectedProvider == null) {
                                return;
                              }

                              final modelName = modelNameController.text.trim();
                              final apiKey = apiController.text.trim();
                              final enteredModelId = modelIdController.text.trim();
                              final targetModelId =
                                enteredModelId.isNotEmpty
                                  ? enteredModelId
                                  : (isEditing ? editingModelId : '$modelName-${DateTime.now().millisecondsSinceEpoch}');

                              final newModelConfig = <String, dynamic>{
                                'provider': selectedProvider,
                                'apiProvider': selectedProvider,
                                'modelName': modelName,
                                'model': modelName,
                                'apiKey': apiKey,
                                if (selectedProvider == 'Custom') ...{
                                  'url': customUrlController.text.trim(),
                                  'httpMethod': customHttpMethod,
                                  'toolCallingMethod': customToolCallingMethod,
                                },
                              };

                              final updatedConfig = Map<String, dynamic>.from(aiState.config);
                              if (isEditing) {
                                updatedConfig.remove(editingModelId);
                              }
                              if (updatedConfig.containsKey(targetModelId)) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Model ID "$targetModelId" already exists')),
                                  );
                                }
                                return;
                              }
                              updatedConfig[targetModelId] = newModelConfig;

                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setString('aiConfig', jsonEncode(updatedConfig));

                              final updatedModelSelected = Map<String, dynamic>.from(aiState.modelSelected);
                              var modelSelectionChanged = false;
                              if (isEditing && editingModelId != targetModelId) {
                                if (updatedModelSelected['code'] == editingModelId) {
                                  updatedModelSelected['code'] = targetModelId;
                                  modelSelectionChanged = true;
                                }
                                if (updatedModelSelected['chat'] == editingModelId) {
                                  updatedModelSelected['chat'] = targetModelId;
                                  modelSelectionChanged = true;
                                }
                              }

                              if (modelSelectionChanged) {
                                await prefs.setString('modelSelected', jsonEncode(updatedModelSelected));
                              }

                              if (context.mounted) {
                                context.read<AIBloc>().add(AIConfigEvent(updatedConfig));
                                if (modelSelectionChanged) {
                                  context.read<AIBloc>().add(ModelSelectEvent(updatedModelSelected));
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isEditing
                                          ? 'Successfully updated model $targetModelId'
                                          : 'Successfully created model $targetModelId',
                                    ),
                                  ),
                                );
                                Navigator.of(context).pop();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.lightBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              isEditing ? 'Update' : 'Create',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } finally {
      customUrlController.dispose();
      _clearModelDialogControllers();
    }
  }

  void _showSSHDialog(
    AppTheme appTheme,
    (int, bool) updateInfo
  ){
    showDialog(
      context: context,
      builder: (ctx){
        return StatefulBuilder(
          builder: (context, setDstate) {
            return Dialog(
              backgroundColor: appTheme.isDark ? const Color(0xff181A26) : Colors.white,
              constraints: BoxConstraints(maxHeight: 600),
              child: Container(
                padding: EdgeInsets.all(20),
                width: double.infinity,
                child: DefaultTextStyle.merge(
                  style: TextStyle(
                    color: appTheme.selectScreenCardTextColor
                  ),
                  child: Form(
                    key: _sshUpdationKey,
                    child: Scrollbar(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: .end,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 12, bottom: 12),
                              child: Row(
                                spacing: 18,
                                children: [
                                  FaIcon(
                                    FontAwesomeIcons.server,
                                    color: Colors.lightBlue
                                  ),
                                  Text(
                                    "Edit remote host",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: .w500
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: Column(
                                spacing: 20,
                                children: [
                                  settingsTextField(
                                    sshServerNameController,
                                    Icons.abc,
                                    "Server name",
                                    appTheme.selectScreenCardTextColor,
                                    "Eg: My server",
                                    (val) =>  val == null || val.isEmpty ? "Please give a name to the server": null,
                                  ),

                                  settingsTextField(
                                    sshUrlController,
                                    Icons.link,
                                    "Host url",
                                    appTheme.selectScreenCardTextColor,
                                    "Eg: ssh://jhon@192.168.1.100",
                                    (val) {
                                      if(val == null || val.isEmpty){
                                        return "Please enter a valid host/ip address";
                                      }

                                      final valUri = Uri.parse(val);
                                      if(valUri.scheme != "ssh") {
                                        return "Invalid ssh url";
                                      } else if(valUri.host.isEmpty){
                                        return "Invalid Or empty host name";
                                      } else if(valUri.userInfo.isEmpty) {
                                        return "Invalid or empty username";
                                      } else {
                                        return null;
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            if(updateInfo.$2) Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: Column(
                                spacing: 20,
                                children: [
                                  settingsTextField(
                                    sshPasswordController,
                                    Icons.password,
                                    "Password",
                                    appTheme.selectScreenCardTextColor,
                                    null,
                                    (val) {
                                      return val == null || val.isEmpty ? "Password field cannot be empty": null;
                                    },
                                    true
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              spacing: 18,
                              children: [
                                TextButton(
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    minimumSize: Size.zero
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    "Cancel",
                                    style: TextStyle(
                                      color: Colors.red
                                    )
                                  )
                                ),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    minimumSize: Size.zero
                                  ),
                                  onPressed: () async{
                                    if (_sshUpdationKey.currentState!.validate()) {
                                      await context.read<SSHServersCubit>().updateServer(
                                        updateInfo.$2
                                        ? SSHLogin(
                                            name: sshServerNameController.text,
                                            id: updateInfo.$1,
                                            url: sshUrlController.text,
                                            password: sshPasswordController.text
                                          )
                                        : SSHPrivateKey(
                                          name: sshServerNameController.text,
                                          id: updateInfo.$1,
                                          url: sshUrlController.text,
                                        )
                                      );
                                      sshServerNameController.text = "";
                                      sshUrlController.text = "";
                                      sshPasswordController.text = "";
                                      if(context.mounted) Navigator.pop(context);
                                      if(context.mounted) Navigator.pop(context);
                                    }
                                  },
                                  child: Text(
                                    "Save",
                                    style: TextStyle(
                                      color: Colors.lightBlue
                                    ),
                                  ),
                                ),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    minimumSize: Size.zero
                                  ),
                                  onPressed: () async{
                                    if(_sshUpdationKey.currentState!.validate()){
                                      final server = updateInfo.$2
                                        ? SSHLogin(
                                          name: sshServerNameController.text,
                                          id: updateInfo.$1,
                                          url: sshUrlController.text,
                                          password: sshPasswordController.text
                                        )

                                        : SSHPrivateKey(
                                            name: sshServerNameController.text,
                                            id: updateInfo.$1,
                                            url: sshUrlController.text,
                                          );
                                      final result = await server.connect();
                                      if(context.mounted){
                                        if(server.isConnected) context.read<SSHServersCubit>().updateServer(server);
                                        if(result.$1) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              backgroundColor: Colors.green,
                                              content: Text(
                                                result.$2,
                                                style: TextStyle(
                                                  color: Colors.white
                                                )
                                              )
                                            )
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              backgroundColor: Colors.red[600],
                                              content: Text(
                                                result.$2,
                                                style: TextStyle(
                                                  color: Colors.white
                                                )
                                              )
                                            )
                                          );
                                        }
                                      }
                                      if(context.mounted) Navigator.pop(context);
                                      if(context.mounted) Navigator.pop(context);
                                    }
                                  },
                                  child: Text(
                                    "Save & Connect",
                                    style: TextStyle(
                                      color: Colors.greenAccent
                                    ),
                                  )
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
        );
      }
    );
  }

  Future<void> _loadLocalGgufModel(BuildContext context, AppThemeState appThemeState) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['gguf'],
    );
    if (result == null) return;
    final path = result.files.single.path!;
    final fileName = result.files.single.name;

    final nameController = TextEditingController(text: fileName.replaceAll('.gguf', ''));
    
    if(!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: appThemeState.appTheme.isDark ? const Color(0xff2b2b2b) : Colors.white,
        title: const Text('Configure Local LLM'),
        content: Form(
          key: _ggufKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Display name')),
              settingsTextField(
                nameController,
                Icons.abc,
                "Display name",
                appThemeState.appTheme.selectScreenCardTextColor,
                null,
                (val) => val == null || val.isEmpty ? "Display name cannot be empty" : null
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () {
            if(_ggufKey.currentState!.validate()){
              Navigator.pop(ctx, false);
            }
          }, child: const Text('Add')),
        ],
      ),
    );

    if (confirmed != true) return;

    final prefs = await SharedPreferences.getInstance();
    final aiConfigStr = await getAiConfig();
    Map<String, dynamic> aiConfig = jsonDecode(aiConfigStr);
    final modelId = 'LocalLlama-${DateTime.now().millisecondsSinceEpoch}';
    aiConfig[modelId] = {
      'provider': 'LocalLlama',
      'apiProvider': 'LocalLlama',
      'modelName': nameController.text,
      'model': nameController.text,
      'modelPath': path,
      'threads': 4,
      'contextSize': 4096,
      'gpuLayers': 0,
    };
    await prefs.setString('aiConfig', jsonEncode(aiConfig));
    if (context.mounted) {
      context.read<AIBloc>().add(AIConfigEvent(aiConfig));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Model "${nameController.text}" added to AI models')),
      );

      final modelSelectedStr = await getModelSelected();
      Map<String, dynamic> modelSelected = jsonDecode(modelSelectedStr);
      if ((modelSelected['chat'] as String? ?? '').isEmpty) {
        modelSelected['chat'] = modelId;
        await prefs.setString('modelSelected', jsonEncode(modelSelected));
        if(context.mounted) context.read<AIBloc>().add(ModelSelectEvent(modelSelected));
      }
    }
  }

  @override void dispose() {
    apiController.dispose();
    modelNameController.dispose();
    modelIdController.dispose();
    scrollController.dispose();
    terminalThemeScroll.dispose();
    themeScroll.dispose();
    fontScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConfigBloc, ConfigState>(
      builder: (context, configState) {
        final theme = configState.codeForgeConfig['theme'];
        final fontFamily = configState.codeForgeConfig['fontFamily'];
        final isIndentEnabled = configState.codeForgeConfig['indentLineStatus'];
        final lineWrap = configState.codeForgeConfig['lineWrap'];
        final enableFolding = configState.codeForgeConfig['enableFolding'];
        final terminalThemeId = (configState.codeForgeConfig['terminalTheme'] ?? defaultTerminalThemeId).toString();
        final selectedTerminalThemePreset = terminalThemePresetById(terminalThemeId);
        return BlocBuilder<AppThemeBloc, AppThemeState>(
          builder: (context, appThemeState) {
            return Scaffold(
              backgroundColor: appThemeState.appTheme.isDark ? const Color(0xff181A26) : null,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                title: Text(
                  "Settings",
                  style: TextStyle(
                    fontSize: 28,
                    color: appThemeState.appTheme.selectScreenCardTextColor
                  )
                )
              ),
              body: Padding(
                padding: const EdgeInsets.only(left: 3, top: 5),
                child: Scrollbar(
                  controller: scrollController,
                  child: ListView(
                    controller: scrollController,
                    children: [
                      settingsType("General", appThemeState.appTheme.isDark),
                      settingsTile(
                        null,
                        "Auto Save",
                        Icon(Icons.save, color: appThemeState.appTheme.selectScreenCardTextColor, size: 19),
                        appThemeState.appTheme.isDark,
                        trailing: SizedBox(
                          height: 30,
                          width: 55,
                          child: BlocBuilder<GeneralBloc, GeneralState>(
                            builder: (context, generalState) {
                              return FlutterSwitch(
                                toggleColor: Color(0xff002b6e),
                                inactiveToggleColor: Colors.white,
                                activeColor: Color(0xffb0c6fe),
                                value: generalState.generalSettings['autoSave'] ?? true,
                                onToggle: (value) async{
                                  final prefs = await SharedPreferences.getInstance();
                                  final currentState = configState.codeForgeConfig;
                                  currentState['autoSave'] = value;
                                  await prefs.setString('codeForgeConfig', jsonEncode(currentState));
                                  prefs.setInt("fontSize", value ? 20 : 15);
                                  if(context.mounted) {
                                    final currentval = context.read<GeneralBloc>().state.generalSettings;
                                    currentval['autoSave'] = value;
                                    context.read<GeneralBloc>().add(GeneralEvent(generalSettings: currentval));
                                  }
                                }
                              );
                            },
                          ),
                        ),
                        subTitle: configState.fontSize > 15 ? "Large" : "Normal"
                      ),
                      settingsDivider,
                      settingsType("Appearance", appThemeState.appTheme.isDark),
                      settingsTile(
                        null,
                        "App Theme",
                        appThemeState.appTheme.isDark ? Icon(
                          Icons.dark_mode,
                          color: Colors.grey,
                        ) : Icon(
                          Icons.light_mode,
                          color: const Color.fromARGB(255, 36, 36, 36),
                        ),
                        appThemeState.appTheme.isDark,
                        subTitle: appThemeState.appTheme.isDark ? "Dark" : "Light",
                        trailing: SizedBox(
                          height: 30,
                          width: 55,
                          child: FlutterSwitch(
                            toggleColor: Color(0xff002b6e),
                            inactiveToggleColor: Colors.white,
                            activeColor: Color(0xffb0c6fe),
                            activeIcon: Icon(Icons.dark_mode, color: Colors.white,),
                            inactiveIcon: Icon(Icons.light_mode),
                            value: appThemeState.appTheme.isDark,
                            onToggle: (value) async{
                              final prefs = await SharedPreferences.getInstance();
                              if(value){
                                if(context.mounted) context.read<AppThemeBloc>().add(AppThemeEvent(appTheme: DarkTheme()));
                                prefs.setString("savedAppTheme", "dark");
                              }
                              else{
                                if(context.mounted) context.read<AppThemeBloc>().add(AppThemeEvent(appTheme: LightTheme()));
                                prefs.setString("savedAppTheme", "light");
                              }
                            }
                          ),
                        )
                      ),
                      settingsTile(() {
                        showDialog(context: context, builder: (dialogContext) {
                          String selectedTheme = theme;
                          String themeSearchQuery = '';
                          bool hasAutoScrolled = false;
                          return StatefulBuilder(
                            builder: (context, setDialogState) {
                              final filteredThemes = highlightThemes.entries.where((entry) {
                                if (themeSearchQuery.isEmpty) {
                                  return true;
                                }
                                final normalizedThemeName = entry.key.toLowerCase();
                                return normalizedThemeName.contains(themeSearchQuery);
                              }).toList();

                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!hasAutoScrolled && themeSearchQuery.isEmpty && themeScroll.hasClients) {
                                  final selectedIndex = highlightThemes.keys.toList().indexOf(selectedTheme);
                                  if (selectedIndex >= 0) {
                                    themeScroll.jumpTo(selectedIndex * 72);
                                  }
                                  hasAutoScrolled = true;
                                }
                              });
                              return AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                backgroundColor: appThemeState.appTheme.isDark
                                  ? const Color(0xff1e1e2e)
                                  : Colors.white,
                                title: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: appThemeState.appTheme.isDark
                                            ? [const Color(0xff3d3d5c), const Color(0xff2a2a3e)]
                                            : [Colors.blue.shade100, Colors.blue.shade50],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.palette_outlined,
                                            color: appThemeState.appTheme.isDark ? Colors.white : Colors.blue.shade700,
                                            size: 28,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Editor Theme",
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: appThemeState.appTheme.isDark ? Colors.white : Colors.blue.shade900,
                                                  ),
                                                ),
                                                Text(
                                                  "${highlightThemes.length} themes available",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: appThemeState.appTheme.isDark
                                                      ? Colors.white70
                                                      : Colors.blue.shade700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: SizedBox(
                                        height: 40,
                                        child: SearchBar(
                                          onChanged: (value) {
                                            setDialogState(() {
                                              themeSearchQuery = value.trim().toLowerCase();
                                              hasAutoScrolled = false;
                                            });
                                          },
                                          leading: Icon(
                                            Icons.search,
                                            color: appThemeState.appTheme.isDark ? Colors.white70 : Colors.blueGrey.shade600,
                                          ),
                                          hintText: "Search theme",
                                          backgroundColor: WidgetStatePropertyAll(
                                            appThemeState.appTheme.isDark
                                              ? const Color(0xff24243a)
                                              : Colors.blueGrey.shade50,
                                          ),
                                          elevation: const WidgetStatePropertyAll(0),
                                          shadowColor: const WidgetStatePropertyAll(Colors.transparent),
                                          textStyle: WidgetStatePropertyAll(
                                            TextStyle(
                                              color: appThemeState.appTheme.selectScreenCardTextColor,
                                            ),
                                          ),
                                          hintStyle: WidgetStatePropertyAll(
                                            TextStyle(
                                              color: appThemeState.appTheme.isDark ? Colors.white54 : Colors.blueGrey.shade400,
                                            ),
                                          ),
                                          shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            side: BorderSide(
                                              color: appThemeState.appTheme.isDark
                                                ? Colors.white12
                                                : Colors.blueGrey.shade200,
                                            ),
                                          )),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                                content: SizedBox(
                                  width: double.maxFinite,
                                  height: 400,
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: Scrollbar(
                                          controller: themeScroll,
                                          thumbVisibility: true,
                                          child: ListView.builder(
                                            controller: themeScroll,
                                            itemCount: filteredThemes.length,
                                            itemExtent: 73,
                                            itemBuilder: (context, index) {
                                              final themeEntry = filteredThemes[index];
                                              final themeName = themeEntry.key;
                                              final themeData = themeEntry.value;
                                              final isSelected = themeName == selectedTheme;
                                              final bgColor = themeData['root']?.backgroundColor ?? Colors.grey;
                                              final textColor = themeData['root']?.color ?? Colors.white;

                                              return Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 4),
                                                child: Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    borderRadius: BorderRadius.circular(12),
                                                    onTap: () async {
                                                      setDialogState(() => selectedTheme = themeName);
                                                      final prefs = await SharedPreferences.getInstance();
                                                      final currentState = configState.codeForgeConfig;
                                                      currentState['theme'] = themeName;
                                                      await prefs.setString('codeForgeConfig', jsonEncode(currentState));
                                                      if (context.mounted) {
                                                        context.read<ConfigBloc>().add(ChangeConfigEvent(currentState));
                                                        Navigator.of(dialogContext).pop();
                                                      }
                                                    },
                                                    child: Container(
                                                      padding: const EdgeInsets.all(12),
                                                      decoration: BoxDecoration(
                                                        color: isSelected
                                                          ? (appThemeState.appTheme.isDark
                                                            ? Colors.blue.withAlpha(40)
                                                            : Colors.blue.withAlpha(30))
                                                          : Colors.transparent,
                                                        borderRadius: BorderRadius.circular(12),
                                                        border: Border.all(
                                                          color: isSelected
                                                            ? Colors.blue
                                                            : Colors.transparent,
                                                          width: 2,
                                                        ),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          Container(
                                                            width: 48,
                                                            height: 48,
                                                            decoration: BoxDecoration(
                                                              color: bgColor,
                                                              borderRadius: BorderRadius.circular(8),
                                                              border: Border.all(
                                                                color: appThemeState.appTheme.isDark  ? Colors.white24 : Colors.black12,
                                                              ),
                                                            ),
                                                            child: Center(
                                                              child: Text(
                                                                'Aa',
                                                                style: TextStyle(
                                                                  color: textColor,
                                                                  fontWeight: FontWeight.bold,
                                                                  fontSize: 16,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(width: 16),
                                                          Expanded(
                                                            child: Text(
                                                              themeName.replaceFirst("base16-", "").capitalize(),
                                                              style: TextStyle(
                                                                color: appThemeState.appTheme.selectScreenCardTextColor,
                                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                              ),
                                                            ),
                                                          ),
                                                          if (isSelected)
                                                            Icon(
                                                              Icons.check_circle,
                                                              color: Colors.blue,
                                                              size: 24,
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      if (filteredThemes.isEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 12),
                                          child: Text(
                                            'No themes match "$themeSearchQuery".',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: appThemeState.appTheme.isDark ? Colors.white70 : Colors.blueGrey.shade600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(dialogContext).pop(),
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: appThemeState.appTheme.isDark
                                          ? Colors.white70
                                          : Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        });
                      }, 'Editor Theme',
                        Icon(Icons.color_lens, size: 22, color: appThemeState.appTheme.selectScreenCardTextColor),
                        appThemeState.appTheme.isDark,
                        subTitle: (theme as String).capitalize()
                      ),
                      settingsTile(
                        (){
                          showDialog(context: context, builder: (dialogContext) {
                            String selectedFont = configState.codeForgeConfig['fontFamily'];
                            return StatefulBuilder(
                              builder: (context, setDialogState) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (fontScroll.hasClients) {
                                    final selectedIndex = fonts.indexOf(selectedFont);
                                    if (selectedIndex >= 0) {
                                      fontScroll.jumpTo(selectedIndex * 72);
                                    }
                                  }
                                });
                                return AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  backgroundColor: appThemeState.appTheme.isDark
                                    ? const Color(0xff1e1e2e)
                                    : Colors.white,
                                  title: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: appThemeState.appTheme.isDark
                                          ? [const Color(0xff3d3d5c), const Color(0xff2a2a3e)]
                                          : [Colors.purple.shade100, Colors.purple.shade50],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        FaIcon(
                                          FontAwesomeIcons.font,
                                          color: appThemeState.appTheme.isDark ? Colors.white : Colors.purple.shade700,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Font Style",
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: appThemeState.appTheme.isDark ? Colors.white : Colors.purple.shade900,
                                                ),
                                              ),
                                              Text(
                                                "${fonts.length} fonts available",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: appThemeState.appTheme.isDark
                                                    ? Colors.white70
                                                    : Colors.purple.shade700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  content: SizedBox(
                                    width: double.maxFinite,
                                    height: 400,
                                    child: Scrollbar(
                                      controller: fontScroll,
                                      thumbVisibility: true,
                                      child: ListView.builder(
                                        controller: fontScroll,
                                        itemCount: fonts.length,
                                        itemBuilder: (context, index) {
                                          final fontName = fonts[index];
                                          final isSelected = fontName == selectedFont;

                                          return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 4),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                borderRadius: BorderRadius.circular(12),
                                                onTap: () async {
                                                  setDialogState(() => selectedFont = fontName);
                                                  final currentState = configState.codeForgeConfig;
                                                  currentState['fontFamily'] = fontName;
                                                  final prefs = await SharedPreferences.getInstance();
                                                  await prefs.setString('codeForgeConfig', jsonEncode(currentState));
                                                  if (context.mounted) {
                                                    context.read<ConfigBloc>().add(ChangeConfigEvent(currentState));
                                                    Navigator.of(dialogContext).pop();
                                                  }
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: isSelected
                                                      ? (appThemeState.appTheme.isDark
                                                        ? Colors.purple.withAlpha(40)
                                                        : Colors.purple.withAlpha(30))
                                                      : Colors.transparent,
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(
                                                      color: isSelected
                                                        ? Colors.purple
                                                        : Colors.transparent,
                                                      width: 2,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [

                                                      Container(
                                                        width: 48,
                                                        height: 48,
                                                        decoration: BoxDecoration(
                                                          color: appThemeState.appTheme.isDark
                                                            ? const Color(0xff2a2a3e)
                                                            : Colors.grey.shade100,
                                                          borderRadius: BorderRadius.circular(8),
                                                          border: Border.all(
                                                            color: appThemeState.appTheme.isDark
                                                              ? Colors.white24
                                                              : Colors.black12,
                                                          ),
                                                        ),
                                                        child: Center(
                                                          child: Text(
                                                            'Aa',
                                                            style: TextStyle(
                                                              fontFamily: fontName,
                                                              color: appThemeState.appTheme.selectScreenCardTextColor,
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 16,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 16),
                                                      Expanded(
                                                        child: Text(
                                                          fontName.capitalize(),
                                                          style: TextStyle(
                                                            fontFamily: fontName,
                                                            color: appThemeState.appTheme.selectScreenCardTextColor,
                                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                          ),
                                                        ),
                                                      ),
                                                      if (isSelected)
                                                        Icon(
                                                          Icons.check_circle,
                                                          color: Colors.purple,
                                                          size: 24,
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(dialogContext).pop(),
                                      child: Text(
                                        'Cancel',
                                        style: TextStyle(
                                          color: appThemeState.appTheme.isDark
                                            ? Colors.white70
                                            : Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          });
                        },
                        "Font Style",
                        FaIcon(FontAwesomeIcons.font,color: appThemeState.appTheme.selectScreenCardTextColor, size: 19),
                        appThemeState.appTheme.isDark,
                        subTitle: (fontFamily as String).capitalize(),
                      ),
                      settingsTile(
                        null,
                        "Indent Guilde line",
                        Icon(
                          Icons.format_line_spacing_sharp,
                          color: appThemeState.appTheme.selectScreenCardTextColor,
                          size: 19
                        ),
                        appThemeState.appTheme.isDark,
                        trailing: SizedBox(
                          height: 30,
                          width: 55,
                          child: FlutterSwitch(
                            toggleColor: Color(0xff002b6e),
                            inactiveToggleColor: Colors.white,
                            activeColor: Color(0xffb0c6fe),
                            value: isIndentEnabled,
                            onToggle: (value) async{
                              final prefs = await SharedPreferences.getInstance();
                              final currentState = configState.codeForgeConfig;
                              currentState['indentLineStatus'] = value;
                              if(context.mounted) context.read<ConfigBloc>().add(ChangeConfigEvent(currentState));
                              prefs.setString("codeForgeConfig", jsonEncode(currentState));
                            }
                          ),
                        ),
                        subTitle: isIndentEnabled ? "Enabled" : "Disabled"
                      ),
                      settingsTile(
                        null,
                        "Line Wrap",
                        Icon(
                          Icons.wrap_text,
                          color: appThemeState.appTheme.selectScreenCardTextColor,
                          size: 19
                        ),
                        appThemeState.appTheme.isDark,
                        trailing: SizedBox(
                          height: 30,
                          width: 55,
                          child: FlutterSwitch(
                            toggleColor: Color(0xff002b6e),
                            inactiveToggleColor: Colors.white,
                            activeColor: Color(0xffb0c6fe),
                            value: lineWrap,
                            onToggle: (value) async{
                              final prefs = await SharedPreferences.getInstance();
                              final currentState = configState.codeForgeConfig;
                              currentState['lineWrap'] = value;
                              if(context.mounted) context.read<ConfigBloc>().add(ChangeConfigEvent(currentState));
                              prefs.setString("codeForgeConfig", jsonEncode(currentState));
                            }
                          ),
                        ),
                        subTitle: lineWrap ? "Enabled" : "Disabled"
                      ),
                      settingsTile(
                        null,
                        "Code Folding",
                        Icon(
                          Icons.blur_linear,
                          color:  appThemeState.appTheme.selectScreenCardTextColor,
                          size: 19
                        ),
                        appThemeState.appTheme.isDark,
                        trailing: SizedBox(
                          height: 30,
                          width: 55,
                          child: FlutterSwitch(
                            toggleColor: Color(0xff002b6e),
                            inactiveToggleColor: Colors.white,
                            activeColor: Color(0xffb0c6fe),
                            value: enableFolding,
                            onToggle: (value) async{
                              final prefs = await SharedPreferences.getInstance();
                              final currentState = configState.codeForgeConfig;
                              currentState['enableFolding'] = value;
                              if(context.mounted) context.read<ConfigBloc>().add(ChangeConfigEvent(currentState));
                              prefs.setString("codeForgeConfig", jsonEncode(currentState));
                            }
                          ),
                        ),
                        subTitle: enableFolding ? "Enabled" : "Disabled"
                      ),
                      const SizedBox(height: 25),
                      Align(
                        alignment: Alignment.center,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxHeight: 320,
                              maxWidth: 365
                            ),
                            child: CodeForge(
                              lineWrap: lineWrap,
                              enableFolding: enableFolding,
                              selectionStyle: CodeSelectionStyle(
                                selectionColor: Colors.blueAccent.withAlpha(80),
                                cursorBubbleColor: Colors.blue,
                              ),
                              key: ValueKey(CodeForgeDemoKey(
                                theme: theme,
                                fontFamily: fontFamily,
                                indentLineStatus: isIndentEnabled,
                                lineWrap: lineWrap,
                                enableFolding: enableFolding,
                                isDark: appThemeState.appTheme.isDark,

                              )),
                              enableGuideLines: isIndentEnabled,
                              language: languages[7].language,
                              editorTheme: highlightThemes[theme],
                              textStyle: TextStyle(fontFamily: fontFamily, fontSize: 16),
                              initialText: demoCode,
                              readOnly: true,
                              verticalScrollPhysics: NeverScrollableScrollPhysics(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      settingsTile(
                        () {
                          showDialog(
                            context: context,
                            builder: (dialogContext) {
                              String selectedTerminalTheme = terminalThemeId;
                              return StatefulBuilder(
                                builder: (context, setDialogState) {
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (!terminalThemeScroll.hasClients) {
                                      return;
                                    }
                                    final selectedIndex = terminalThemePresets.keys.toList().indexOf(selectedTerminalTheme);
                                    if (selectedIndex >= 0) {
                                      terminalThemeScroll.jumpTo(selectedIndex * 72);
                                    }
                                  });

                                  return AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    backgroundColor: appThemeState.appTheme.isDark
                                      ? const Color(0xff1e1e2e)
                                      : Colors.white,
                                    title: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: appThemeState.appTheme.isDark
                                            ? [const Color(0xff314455), const Color(0xff253242)]
                                            : [Colors.teal.shade100, Colors.teal.shade50],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.terminal,
                                            color: appThemeState.appTheme.isDark
                                              ? Colors.white
                                              : Colors.teal.shade700,
                                            size: 26,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Terminal Theme',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: appThemeState.appTheme.isDark ? Colors.white : Colors.teal.shade900,
                                                  ),
                                                ),
                                                Text('${terminalThemePresets.length} palettes available',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: appThemeState .appTheme.isDark ? Colors.white70 : Colors.teal.shade700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    content: SizedBox(
                                      width: double.maxFinite,
                                      height: 380,
                                      child: Scrollbar(
                                        controller: terminalThemeScroll,
                                        thumbVisibility: true,
                                        child: ListView.builder(
                                          controller: terminalThemeScroll,
                                          itemCount: terminalThemePresets.length,
                                          itemBuilder: (context, index) {
                                            final entry = terminalThemePresets.entries.elementAt(index);
                                            final preset = entry.value;
                                            final isSelected = preset.id == selectedTerminalTheme;

                                            return Padding(
                                              padding: const EdgeInsets.symmetric(
                                                vertical: 4,
                                              ),
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  borderRadius: BorderRadius.circular(12),
                                                  onTap: () async {
                                                    setDialogState(() {
                                                      selectedTerminalTheme = preset.id;
                                                    });
                                                    final currentState = Map<String, dynamic>.from(
                                                      configState.codeForgeConfig,
                                                    );
                                                    currentState['terminalTheme'] = preset.id;
                                                    await _saveCodeForgeConfig(
                                                      currentState,
                                                    );
                                                    if (context.mounted) {
                                                      Navigator.of(dialogContext).pop();
                                                    }
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets.all(12),
                                                    decoration: BoxDecoration(
                                                      color: isSelected
                                                        ? (appThemeState.appTheme.isDark ? Colors.teal.withAlpha(35) : Colors.teal.withAlpha(22))
                                                        : Colors.transparent,
                                                      borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(
                                                        color: isSelected
                                                          ? Colors.teal
                                                          : Colors.transparent,
                                                        width: 2,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Container(
                                                          width: 48,
                                                          height: 48,
                                                          decoration: BoxDecoration(
                                                            color: preset.backgroundColor,
                                                            borderRadius: BorderRadius.circular(8),
                                                            border: Border.all(
                                                              color: appThemeState.appTheme.isDark
                                                                ? Colors.white24
                                                                : Colors.black12,
                                                            ),
                                                          ),
                                                          child: Center(
                                                            child: Text(
                                                              r'$>',
                                                              style: TextStyle(
                                                                color: preset.foregroundColor,
                                                                fontWeight: FontWeight.w700,
                                                                fontSize: 14,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 16),
                                                        Expanded(
                                                          child: Text(
                                                            preset.name,
                                                            style: TextStyle(
                                                              color: appThemeState.appTheme.selectScreenCardTextColor,
                                                              fontWeight: isSelected
                                                              ? FontWeight.bold
                                                              : FontWeight.normal,
                                                            ),
                                                          ),
                                                        ),
                                                        if (isSelected)
                                                          const Icon(
                                                            Icons.check_circle,
                                                            color: Colors.teal,
                                                            size: 24,
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(dialogContext).pop(),
                                        child: Text(
                                          'Cancel',
                                          style: TextStyle(
                                            color: appThemeState.appTheme.isDark
                                              ? Colors.white70
                                              : Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        },
                        'Terminal Theme',
                        Icon(
                          Icons.terminal,
                          color: appThemeState.appTheme.selectScreenCardTextColor,
                          size: 19,
                        ),
                        appThemeState.appTheme.isDark,
                        subTitle: selectedTerminalThemePreset.name,
                      ),

                      const SizedBox(height: 20),

                      Align(
                        alignment: Alignment.center,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 365,
                              maxHeight: 220,
                              minWidth: 280,
                              minHeight: 160,
                            ),
                            child: TerminalView(
                              terminal,
                              padding: EdgeInsets.all(7),
                              readOnly: true,
                              theme: selectedTerminalThemePreset.theme,
                              textStyle: TerminalStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 35),
                      settingsDivider,
                      const SizedBox(height: 20),
                      settingsType("Remote host and Termux", appThemeState.appTheme.isDark),
                      BlocBuilder<SSHServersCubit, SSHServersState>(
                        builder: (context, sshState) {
                          final serverList = sshState.serverList;
                          final appTheme = appThemeState.appTheme;
                          return Form(
                            key: _sshFormKey,
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  child: SizedBox(
                                    height: 35,
                                    child: Row(
                                      mainAxisAlignment: .center,
                                      children: [
                                        InkWell(
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(20),
                                            bottomLeft: Radius.circular(20)
                                          ),
                                          onTap: (){
                                            if(sshStackIndex == 0) return;
                                            setState(() => sshStackIndex = 0);
                                          }, child: Container(
                                            alignment: .center,
                                            decoration: BoxDecoration(
                                              color: sshStackIndex == 0 ? Colors.blue : null,
                                              borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(20),
                                                bottomLeft: Radius.circular(20)
                                              ),
                                              border: Border.all(
                                                color: appTheme.selectScreenCardTextColor.withAlpha(150),
                                                width: 1
                                              )
                                            ),
                                            width: 100,
                                            child: Text(
                                              "Login",
                                              style: TextStyle(
                                                color: sshStackIndex == 0 ? Colors.white : Colors.grey.withAlpha(150)
                                              ),
                                            )
                                          )
                                        ),
                                        InkWell(
                                          borderRadius: BorderRadius.only(
                                            topRight: Radius.circular(20),
                                            bottomRight: Radius.circular(20)
                                          ),
                                          onTap: (){
                                            if(sshStackIndex == 1) return;
                                            setState(() => sshStackIndex = 1);
                                          }, child: Container(
                                            alignment: .center,
                                            decoration: BoxDecoration(
                                              color: sshStackIndex == 1 ? Colors.blue : null,
                                              borderRadius: BorderRadius.only(
                                                topRight: Radius.circular(20),
                                                bottomRight: Radius.circular(20)
                                              ),
                                              border: Border.all(
                                                color: appTheme.selectScreenCardTextColor.withAlpha(150),
                                                width: 1
                                              )
                                            ),
                                            width: 100,
                                            child: Text(
                                              "Private key",
                                              style: TextStyle(
                                                color: sshStackIndex == 1 ? Colors.white : Colors.grey.withAlpha(150)
                                              ),
                                            )
                                          )
                                        ),
                                      ]
                                    ),
                                  ),
                                ),

                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: .circular(10),
                                      border: .all(
                                        color: Colors.blue
                                      )
                                    ),
                                    child: Row(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Icon(
                                            Icons.info_outlined,
                                            color: Colors.blue,
                                            size: 18
                                          ),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                            child: RichText(
                                              text: TextSpan(
                                                style: TextStyle(
                                                  color: appTheme.selectScreenCardTextColor,
                                                ),
                                                children: [
                                                  const TextSpan(
                                                    text: 'Make sure to install and start ',
                                                  ),
                                                  TextSpan(
                                                    text: 'ssh',
                                                    style: const TextStyle(
                                                      color: Colors.blue,
                                                      decoration: TextDecoration.underline,
                                                    ),
                                                    recognizer: TapGestureRecognizer()
                                                      ..onTap = () async {
                                                        await launchUrl(
                                                          Uri.parse(
                                                            "https://www.geeksforgeeks.org/linux-unix/ssh-command-in-linux-with-examples/",
                                                          ),
                                                        );
                                                      },
                                                  ),
                                                  const TextSpan(
                                                    text: ' server in your host system.',
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 32, bottom: 25, top: 40),
                                  child: Row(
                                    spacing: 18,
                                    children: [
                                      FaIcon(
                                        FontAwesomeIcons.server,
                                        color: Colors.lightBlue
                                      ),
                                      Text(
                                        "Add a remote host",
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: .w500,
                                          color: appTheme.selectScreenCardTextColor
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 340,
                                  child: Column(
                                    spacing: 15,
                                    children: [
                                      settingsTextField(
                                        sshServerNameController,
                                        Icons.abc,
                                        "Server name",
                                        appTheme.selectScreenCardTextColor,
                                        "Eg: My server",
                                        (val) =>  val == null || val.isEmpty ? "Please give a name to the server": null,
                                      ),
                                            
                                      settingsTextField(
                                        sshUrlController,
                                        Icons.link,
                                        "Host url",
                                        appTheme.selectScreenCardTextColor,
                                        "Eg: ssh://jhon@192.168.1.100",
                                        (val) {
                                          if(val == null || val.isEmpty){
                                            return "Please enter a valid host/ip address";
                                          }
                                            
                                          final valUri = Uri.parse(val);
                                          if(valUri.scheme != "ssh") {
                                            return "Invalid ssh url";
                                          } else if(valUri.host.isEmpty){
                                            return "Invalid Or empty host name";
                                          } else if(valUri.userInfo.isEmpty) {
                                            return "Invalid or empty username";
                                          } else {
                                            return null;
                                          }
                                        },
                                      ),
                                            
                                    ],
                                  ),
                                ),
                            
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: sshStackIndex == 0
                                    ? SizedBox(
                                      width: 380,
                                      child: Column(
                                        children:[
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 20),
                                            child: SizedBox(
                                              child: Container(
                                              padding: EdgeInsets.all(20),
                                              width: double.infinity,
                                              child: DefaultTextStyle.merge(
                                                style: TextStyle(
                                                  color: appTheme.selectScreenCardTextColor
                                                ),
                                                child: Column(
                                                  children: [
                                                    settingsTextField(
                                                      sshPasswordController,
                                                      Icons.password,
                                                      "Password",
                                                      appTheme.selectScreenCardTextColor,
                                                      null,
                                                      (val) {
                                                        if(sshStackIndex == 1) return null;
                                                        return val == null || val.isEmpty ? "Password field cannot be empty": null;
                                                      },
                                                      true
                                                    ),
                                                
                                                    Padding(
                                                      padding: const EdgeInsets.only(top: 35),
                                                      child: SizedBox(
                                                        child: Column(
                                                          spacing: 18,
                                                          children: [
                                                            SizedBox(
                                                              width: 200,
                                                              child: ElevatedButton(
                                                                style: ElevatedButton.styleFrom(
                                                                  backgroundColor: Colors.lightBlue,
                                                                  foregroundColor: Colors.white,
                                                                  shape: RoundedRectangleBorder(
                                                                    borderRadius: .circular(10),
                                                                  )
                                                                  
                                                                ),
                                                                onPressed: () async{
                                                                  if (_sshFormKey.currentState!.validate()) {
                                                                    await context.read<SSHServersCubit>().addServer(
                                                                      SSHLogin(
                                                                        name: sshServerNameController.text,
                                                                        id: DateTime.now().millisecondsSinceEpoch,
                                                                        url: sshUrlController.text,
                                                                        password: sshPasswordController.text
                                                                      )
                                                                    );
                                                                  }
                                                                },
                                                                child: Row(
                                                                  spacing: 5,
                                                                  mainAxisAlignment: .center,
                                                                  children: [
                                                                    const Icon(Icons.save),
                                                                    const Text(
                                                                      "Save",
                                                                      style: TextStyle(
                                                                        fontWeight: .bold
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                            
                                                            SizedBox(
                                                              width: 200,
                                                              child: ElevatedButton(
                                                                style: ElevatedButton.styleFrom(
                                                                  backgroundColor: Colors.green,
                                                                  foregroundColor: Colors.white,
                                                                  shape: RoundedRectangleBorder(
                                                                    borderRadius: .circular(10),
                                                                  )
                                                                ),
                                                                onPressed: () async{
                                                                  final server = SSHLogin(
                                                                    name: sshServerNameController.text,
                                                                    id: DateTime.now().millisecondsSinceEpoch,
                                                                    url: sshUrlController.text,
                                                                    password: sshPasswordController.text
                                                                  );

                                                                  final result = await server.connect();
                                                                  if(!context.mounted) return;
                                                                  await context.read<SSHServersCubit>().addServer(server);
                                                                  if(context.mounted){
                                                                    Navigator.pop(context);
                                                                    if(result.$1) {
                                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                                        SnackBar(
                                                                          backgroundColor: Colors.green,
                                                                          content: Text(
                                                                            result.$2,
                                                                            style: TextStyle(
                                                                              color: Colors.white
                                                                            )
                                                                          )
                                                                        )
                                                                      );
                                                                    } else {
                                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                                        SnackBar(
                                                                          backgroundColor: Colors.red[600],
                                                                          content: Text(
                                                                            result.$2,
                                                                            style: TextStyle(
                                                                              color: Colors.white
                                                                            )
                                                                          )
                                                                        )
                                                                      );
                                                                    }
                                                                  }
                                                                },
                                                                child: Row(
                                                                  mainAxisAlignment: .center,
                                                                  spacing: 5,
                                                                  children: [
                                                                    const Icon(Icons.power),
                                                                    const Text(
                                                                      "Save & Connect",
                                                                      style: TextStyle(
                                                                        fontWeight: .bold
                                                                      ),
                                                                    ),
                                                                  ],
                                                                )
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    )
                                                  ],
                                                ),
                                              ),
                                            ),
                                            ),
                                          ),
                                        ]
                                      ),
                                    )
                            
                                    : Column(
                                      children:[
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 30),
                                          child: SizedBox(
                                            width: 295,
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                shape: RoundedRectangleBorder(borderRadius: .circular(10)),
                                                backgroundColor: Colors.lightBlue,
                                                foregroundColor: Colors.white
                                              ),
                            
                                              onPressed: () async {
                                                setState(() => _isGeneratedKey = false);
                                                await sshKeygen.generate();
                                                setState(() => _isGeneratedKey = true);
                                              },
                            
                                              child: Padding(
                                                padding: const EdgeInsets.only(right: 10, top: 5, bottom: 8),
                                                child: Row(
                                                  mainAxisAlignment: .center,
                                                  spacing: 8,
                                                  children: [
                                                    ((){
                                                      if(_isGeneratedKey == null) {
                                                        return const Icon(
                                                          Icons.key,
                                                          size: 25
                                                        );
                                                      } else if(!_isGeneratedKey!) {
                                                        return const CircularProgressIndicator(
                                                          color: Colors.white,
                                                        );
                                                      } else {
                                                        return const Icon(
                                                          Icons.autorenew,
                                                          size: 25
                                                        );
                                                      }
                                                    })(),
                                                    Column(
                                                      crossAxisAlignment: .start,
                                                      children: [
                                                        ((){
                                                          if(_isGeneratedKey == null) {
                                                            return const Text(
                                                              "Generate keys",
                                                              style: TextStyle(
                                                                fontSize: 16
                                                              )
                                                            );
                                                          } else if(!_isGeneratedKey!) {
                                                            return const Text("Generating...");
                                                          } else {
                                                            return const Text(
                                                              "Regenerate keys",
                                                              style: TextStyle(
                                                                fontSize: 17
                                                              )
                                                            );
                                                          }
                                                        })(),
                                                        Text(
                                                          _isGeneratedKey ?? false
                                                            ? "Caution: Regenerating ssh keys will revoke\nyour access from all hosts."
                                                            : "Generate a public-private key pair\nfor the ssh connection.",
                            
                                                          style: TextStyle(
                                                            fontSize: 9.5,
                                                            color: Colors.white.withAlpha(200)
                                                          )
                                                        )
                                                      ]
                                                    ),
                                                  ],
                                                ),
                                              )
                                            ),
                                          ),
                                        ),
                            
                                        if(_isGeneratedKey ?? false) DefaultTextStyle(
                                          style: TextStyle(
                                            color: appThemeState.appTheme.selectScreenCardTextColor
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.only(left: 25),
                                            child: Column(
                                              crossAxisAlignment: .start,
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.only(left: 5, right: 10, bottom: 20),
                                                  child: Text("After installing and starting ssh in your host system, paste this command:"),
                                                ),
                                                Row(
                                                  children: [
                                                    FaIcon(
                                                      FontAwesomeIcons.linux,
                                                      color: appThemeState.appTheme.selectScreenCardTextColor,
                                                      size: 17
                                                    ),
                                                    Text(" Linux / "),
                                                    FaIcon(
                                                      FontAwesomeIcons.apple,
                                                      color: appThemeState.appTheme.selectScreenCardTextColor,
                                                      size: 17
                                                    ),
                                                    Text(" Mac")
                                                  ],
                                                ),
                                                const SizedBox(height: 10),
                                                copyArea(
                                                  context,
                                                  appTheme,
                                                  "mkdir -p ~/.ssh\n\n"
                                                  "chmod 700 ~/.ssh\n\n"
                                                  "echo \"${SshKeygen.publicKeyFilelocation.readAsStringSync()}\" >> ~/.ssh/authorized_keys\n\n"
                                                  "chmod 600 ~/.ssh/authorized_keys",
                                                  200
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                                  child: Row(
                                                    children: [
                                                      FaIcon(
                                                        FontAwesomeIcons.windows,
                                                        color: appThemeState.appTheme.selectScreenCardTextColor,
                                                        size: 17
                                                      ),
                                                      Text(" Windows powershell"),
                                                    ],
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.only(bottom: 25),
                                                  child: copyArea(
                                                    context,
                                                    appTheme,
                                                    'New-Item -ItemType Directory -Force "\$HOME\\.ssh" | Out-Null; Add-Content "\$HOME\\.ssh\\authorized_keys" "${SshKeygen.publicKeyFilelocation.readAsStringSync()}"',
                                                    135
                                                  ),
                                                ),
                                              ]
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 20),
                                          child: SizedBox(
                                            width: 200,
                                            child: ElevatedButton(
                                              onPressed: () async{
                                                if(_sshFormKey.currentState!.validate()){
                                                  final server = SSHPrivateKey(
                                                    name: sshServerNameController.text,
                                                    id: DateTime.now().millisecondsSinceEpoch,
                                                    url: sshUrlController.text,
                                                  );
                                                  final result = await server.connect();
                                                  if(context.mounted){
                                                    if(server.isConnected) context.read<SSHServersCubit>().addServer(server);
                                                    if(result.$1) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          backgroundColor: Colors.green,
                                                          content: Text(
                                                            result.$2,
                                                            style: TextStyle(
                                                              color: Colors.white
                                                            )
                                                          )
                                                        )
                                                      );
                                                    } else {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          backgroundColor: Colors.red[600],
                                                          content: Text(
                                                            result.$2,
                                                            style: TextStyle(
                                                              color: Colors.white
                                                            )
                                                          )
                                                        )
                                                      );
                                                    }
                                                  }
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: .circular(10)
                                                )
                                              ),
                                              child: const Row(
                                                mainAxisAlignment: .center,
                                                children: [
                                                  Icon(Icons.power),
                                                  Text("Save & Connect")
                                                ]
                                              ),
                                            ),
                                          ),
                                        )
                                      ]
                                    ),
                                ),
                            
                            
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: appThemeState.appTheme.isDark ? Colors.indigo : const Color.fromARGB(255, 199, 181, 248),
                                          borderRadius: BorderRadius.vertical(top: Radius.circular(10))
                                        ),
                                        child: Text(
                                          "Saved remotes",
                                          style: TextStyle(color: appThemeState.appTheme.selectScreenCardTextColor)
                                        )
                                      ),
                                      Container(
                                        alignment: .center,
                                        padding: EdgeInsets.all(15),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
                                          color: appThemeState.appTheme.isDark ? const Color.fromARGB(255, 39, 42, 65) : Colors.grey[200],
                                        ),
                                        width: double.infinity,
                                        child: serverList.isEmpty ? Text(
                                          "No remotes have been configured yet.",
                                          style: TextStyle(
                                            color: appThemeState.appTheme.selectScreenCardTextColor.withAlpha(150),
                                            fontSize: 16
                                          )
                                        ) : ConstrainedBox(
                                          constraints: BoxConstraints(
                                            maxHeight: 450
                                          ),
                                          child: Scrollbar(
                                            child: ListView.builder(
                                              shrinkWrap: true,
                                              itemCount: serverList.length,
                                              itemBuilder: (context, index) {
                                                final server = serverList[index];
                                                final isLogin = server is SSHLogin;
                                                return Card(
                                                  color: appTheme.scaffoldBg,
                                                  child: ListTile(
                                                    onTap: () {
                                                      bool isObscure = true;
                                                      showDialog(
                                                        context: context,
                                                        builder:(context) => StatefulBuilder(
                                                          builder: (context, setTempState) => Dialog(
                                                            backgroundColor: appThemeState.appTheme.isDark ? const Color(0xff181A26) : Colors.white,
                                                            constraints: BoxConstraints(maxHeight: 580),
                                                            child: DefaultTextStyle.merge(
                                                              style: TextStyle(
                                                                color: appThemeState.appTheme.selectScreenCardTextColor,
                                                                fontSize: 15
                                                              ),
                                                              child: Container(
                                                                width: double.infinity,
                                                                padding: EdgeInsets.all(20),
                                                                child: SingleChildScrollView(
                                                                  child: Column(
                                                                    spacing: 10,
                                                                    crossAxisAlignment: .start,
                                                                    children: [
                                                                      Text(
                                                                        "Host Info",
                                                                        style: TextStyle(
                                                                          fontSize: 30
                                                                        ),
                                                                      ),
                                                                      SizedBox(height: 20),
                                                                      Table(
                                                                        border: TableBorder.all(
                                                                          color: appThemeState.appTheme.selectScreenCardTextColor.withAlpha(150),
                                                                          width: 0.5,
                                                                          borderRadius: .circular(15)
                                                                        ),
                                                                        columnWidths: const <int, TableColumnWidth>{
                                                                          0: IntrinsicColumnWidth(),
                                                                          1: FlexColumnWidth(),
                                                                        },
                                                                        children: [
                                                                          TableRow(
                                                                            children: [
                                                                              Padding(
                                                                                padding: const EdgeInsets.all(8.0),
                                                                                child: const Text("name"),
                                                                              ),
                                                                              Padding(
                                                                                padding: const EdgeInsets.all(8.0),
                                                                                child: Text(server.name),
                                                                              ),
                                                                            ]
                                                                          ),
                                                                          TableRow(
                                                                            children: [
                                                                              Padding(
                                                                                padding: const EdgeInsets.all(8.0),
                                                                                child: const Text("id"),
                                                                              ),
                                                                              Padding(
                                                                                padding: const EdgeInsets.all(8.0),
                                                                                child: Text(server.id.toString()),
                                                                              ),
                                                                            ]
                                                                          ),
                                                                          TableRow(
                                                                            children: [
                                                                              Padding(
                                                                                padding: const EdgeInsets.all(8.0),
                                                                                child: const Text("server url"),
                                                                              ),
                                                                              Padding(
                                                                                padding: const EdgeInsets.all(8.0),
                                                                                child: Text(server.url),
                                                                              ),
                                                                            ]
                                                                          ),
                                                                          TableRow(
                                                                            children: [
                                                                              Padding(
                                                                                padding: const EdgeInsets.all(8.0),
                                                                                child: const Text("type"),
                                                                              ),
                                                                              Padding(
                                                                                padding: const EdgeInsets.all(8.0),
                                                                                child: Text(isLogin ? "login" : "private key"),
                                                                              ),
                                                                            ]
                                                                          ),
                                                                          TableRow(
                                                                            children: [
                                                                              Padding(
                                                                                padding: const EdgeInsets.all(8.0),
                                                                                child: const Text("host"),
                                                                              ),
                                                                              Padding(
                                                                                padding: const EdgeInsets.all(8.0),
                                                                                child: Text(server.host),
                                                                              )
                                                                            ]
                                                                          ),
                                                                          if(isLogin) TableRow(
                                                                            children: [
                                                                              Padding(
                                                                                padding: const EdgeInsets.all(8.0),
                                                                                child: const Text("username"),
                                                                              ),
                                                                              Padding(
                                                                                padding: const EdgeInsets.all(8.0),
                                                                                child: Text(server.username),
                                                                              )
                                                                            ]
                                                                          ),
                                                                                              
                                                                          TableRow(
                                                                            children: [
                                                                              Padding(
                                                                                padding: const EdgeInsets.all(8.0),
                                                                                child: Text(isLogin ? "password" : "private key"),
                                                                              ),
                                                                              Padding(
                                                                                padding: const EdgeInsets.all(8.0),
                                                                                child: Wrap(
                                                                                  children: [
                                                                                    Text(
                                                                                      isLogin
                                                                                        ? isObscure
                                                                                          ? "*" * server.password.length
                                                                                          : server.password
                                                                                        : isObscure
                                                                                          ? "${"*" * 8}\u00B7\u00B7\u00B7"
                                                                                          : SshKeygen.privateKeyFilelocation.path
                                                                                    ),
                                                                                    Padding(
                                                                                      padding: const EdgeInsets.only(left: 17),
                                                                                      child: InkWell(
                                                                                        onTap: () => setTempState(() => isObscure = !isObscure),
                                                                                        child: Icon(
                                                                                          isObscure ? Icons.visibility : Icons.visibility_off,
                                                                                          color: appThemeState.appTheme.selectScreenCardTextColor,
                                                                                          size: 20
                                                                                        ),
                                                                                      ),
                                                                                    )
                                                                                  ],
                                                                                ),
                                                                              )
                                                                            ]
                                                                          )
                                                                        ],
                                                                      ),
                                                                      Center(
                                                                        child: Padding(
                                                                          padding: const EdgeInsets.only(top: 20),
                                                                          child: SizedBox(
                                                                            width: 200,
                                                                            child: Column(
                                                                              spacing: 5,
                                                                              children: [
                                                                                ElevatedButton(
                                                                                  style: ElevatedButton.styleFrom(
                                                                                    backgroundColor: server.isConnected ? Colors.green : appThemeState.appTheme.scaffoldBg,
                                                                                    shape: RoundedRectangleBorder(
                                                                                      borderRadius: .circular(12),
                                                                                      side: BorderSide(
                                                                                        color: Colors.green
                                                                                      )
                                                                                    )
                                                                                  ),
                                                                                  onPressed: ()async {
                                                                                    if(server.isConnected){
                                                                                      showDialog(
                                                                                        context: context,
                                                                                        builder: (context) => StatefulBuilder(
                                                                                          builder: (context, _) {
                                                                                            return AlertDialog(
                                                                                              backgroundColor: appThemeState.appTheme.isDark ? appThemeState.appTheme.scaffoldBg : null,
                                                                                              title: Text(
                                                                                                'Disconnect ${server.host}?',
                                                                                                style: TextStyle(
                                                                                                  color: appThemeState.appTheme.selectScreenCardTextColor,
                                                                                                  fontSize: 20
                                                                                                ),
                                                                                              ),
                                                                                              content: Text(
                                                                                                "Are you sure you want to disconnect from this host?",
                                                                                                style: TextStyle(
                                                                                                  color: appThemeState.appTheme.selectScreenCardTextColor.withAlpha(150),
                                                                                                  fontSize: 16
                                                                                                )
                                                                                              ),
                                                                                              actions: [
                                                                                                ElevatedButton(
                                                                                                  onPressed: ()=> Navigator.of(context).pop(),
                                                                                                  child: Text('Cancel')
                                                                                                ),
                                                                                                ElevatedButton(
                                                                                                  onPressed: () {
                                                                                                    server.disconnect();
                                                                                                    context.read<SSHServersCubit>().updateServer(server);
                                                                                                    Navigator.of(context).pop();
                                                                                                    Navigator.of(context).pop();
                                                                                                  },
                                                                                                  style: ButtonStyle(
                                                                                                    backgroundColor: WidgetStateProperty.all<Color>(Colors.red)
                                                                                                  ),
                                                                                                  child: Text('Disconnect', style: TextStyle(color: Colors.white))
                                                                                                )
                                                                                              ],
                                                                                            );
                                                                                          }
                                                                                        )
                                                                                      );
                                                                                      return;
                                                                                    }
                                                                  
                                                                                    final result = await server.connect();
                                                                                    if(context.mounted){
                                                                                      context.read<SSHServersCubit>().updateServer(server);
                                                                                      Navigator.pop(context);
                                                                                      if(result.$1) {
                                                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                                                          SnackBar(
                                                                                            backgroundColor: Colors.green,
                                                                                            content: Text(
                                                                                              result.$2,
                                                                                              style: TextStyle(
                                                                                                color: Colors.white
                                                                                              )
                                                                                            )
                                                                                          )
                                                                                        );
                                                                                      } else {
                                                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                                                          SnackBar(
                                                                                            backgroundColor: Colors.red[600],
                                                                                            content: Text(
                                                                                              result.$2,
                                                                                              style: TextStyle(
                                                                                                color: Colors.white
                                                                                              )
                                                                                            )
                                                                                          )
                                                                                        );
                                                                                      }
                                                                                    }
                                                                                  },
                                                                                  child: Row(
                                                                                    spacing: 7,
                                                                                    mainAxisAlignment: .center,
                                                                                    children: [
                                                                                      Icon(
                                                                                        Icons.power,
                                                                                        color: server.isConnected ? Colors.white : Colors.green,
                                                                                        size: 21
                                                                                      ),
                                                                                      Text(
                                                                                        server.isConnected ? "Connected" : "Connect",
                                                                                        style: TextStyle(
                                                                                          color: Colors.white,
                                                                                          fontSize: 16.5
                                                                                        ),
                                                                                      )
                                                                                    ],
                                                                                  )
                                                                                ),
                                                                                ElevatedButton(
                                                                                  style: ElevatedButton.styleFrom(
                                                                                    backgroundColor: appThemeState.appTheme.scaffoldBg,
                                                                                    shape: RoundedRectangleBorder(
                                                                                      borderRadius: .circular(12),
                                                                                      side: BorderSide(
                                                                                        color: Colors.blue
                                                                                      )
                                                                                    )
                                                                                  ),
                                                                                  onPressed: (){
                                                                                    sshServerNameController.text = server.name;
                                                                                    sshUrlController.text = server.url;
                                                                                    final isLogin = server is SSHLogin;
                                                                                    if(isLogin){
                                                                                      sshPasswordController.text= server.password;
                                                                                    }
                                                                                              
                                                                                    _showSSHDialog(
                                                                                      appThemeState.appTheme,
                                                                                      (server.id, isLogin)
                                                                                    );
                                                                                              
                                                                                  },
                                                                                  child: Row(
                                                                                    spacing: 12,
                                                                                    mainAxisAlignment: .center,
                                                                                    children: [
                                                                                      Icon(
                                                                                        Icons.edit,
                                                                                        color: Colors.blue,
                                                                                        size: 21
                                                                                      ),
                                                                                      Text(
                                                                                        "Edit",
                                                                                        style: TextStyle(
                                                                                          color: Colors.white,
                                                                                          fontSize: 16.5
                                                                                        ),
                                                                                    )
                                                                                    ],
                                                                                  )
                                                                                ),
                                                                                ElevatedButton(
                                                                                  style: ElevatedButton.styleFrom(
                                                                                    backgroundColor: appThemeState.appTheme.scaffoldBg,
                                                                                    shape: RoundedRectangleBorder(
                                                                                      borderRadius: .circular(12),
                                                                                      side: BorderSide(
                                                                                        color: Colors.red
                                                                                      )
                                                                                    )
                                                                                  ),
                                                                                  onPressed: (){
                                                                                    showDialog(
                                                                                      context: context,
                                                                                      builder: (context) => StatefulBuilder(
                                                                                        builder: (context, _) {
                                                                                          return AlertDialog(
                                                                                            backgroundColor: appThemeState.appTheme.isDark ? appThemeState.appTheme.scaffoldBg : null,
                                                                                            title: Text(
                                                                                              'Delete ${server.name}?',
                                                                                              style: TextStyle(
                                                                                                color: appThemeState.appTheme.selectScreenCardTextColor,
                                                                                                fontSize: 20
                                                                                              ),
                                                                                            ),
                                                                                            content: Text(
                                                                                              "Are you sure you want to delete this remote host?",
                                                                                              style: TextStyle(
                                                                                                color: appThemeState.appTheme.selectScreenCardTextColor.withAlpha(150),
                                                                                                fontSize: 16
                                                                                              )
                                                                                            ),
                                                                                            actions: [
                                                                                              ElevatedButton(
                                                                                                onPressed: ()=> Navigator.of(context).pop(),
                                                                                                child: Text('Cancel')
                                                                                              ),
                                                                                              ElevatedButton(
                                                                                                onPressed: () {
                                                                                                  context.read<SSHServersCubit>().removeServer(server.id);
                                                                                                  Navigator.of(context).pop();
                                                                                                  Navigator.of(context).pop();
                                                                                                },
                                                                                                style: ButtonStyle(
                                                                                                  backgroundColor: WidgetStateProperty.all<Color>(Colors.red)
                                                                                                ),
                                                                                                child: Text('Delete', style: TextStyle(color: Colors.white))
                                                                                              )
                                                                                            ],
                                                                                          );
                                                                                        }
                                                                                      )
                                                                                    );
                                                                                  },
                                                                                  child: Row(
                                                                                    spacing: 10,
                                                                                    mainAxisAlignment: .center,
                                                                                    children: [
                                                                                      Icon(
                                                                                        Icons.delete,
                                                                                        color: Colors.red,
                                                                                        size: 21
                                                                                      ),
                                                                                      Text(
                                                                                        "Delete",
                                                                                        style: TextStyle(
                                                                                          color: Colors.white,
                                                                                          fontSize: 16.5
                                                                                        ),
                                                                                      )
                                                                                    ],
                                                                                  )
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadiusGeometry.circular(10),
                                                    ),
                                                    title: Text(server.name, overflow: .ellipsis),
                                                    titleTextStyle: TextStyle(
                                                      fontSize: 16,
                                                      fontFamily: "monospace",
                                                      color: appTheme.selectScreenCardTextColor,
                                                    ),
                                                    subtitleTextStyle: TextStyle(
                                                      color: appTheme.selectScreenCardTextColor,
                                                      fontSize: 13
                                                    ),
                                                    leading: FaIcon(
                                                      FontAwesomeIcons.server,
                                                      color: Colors.lightBlue
                                                    ),
                                                    subtitle: Row(
                                                      spacing: 5,
                                                      children: [
                                                        const Text("status: "),
                                                        Padding(
                                                          padding: const EdgeInsets.only(top: 2.5),
                                                          child: Container(
                                                            padding: EdgeInsets.symmetric(vertical: 0.5, horizontal: 3.5),
                                                            decoration: BoxDecoration(
                                                              border: Border.all(
                                                                width: server.isConnected ? 1 : 0.5,
                                                                color: server.isConnected ? Colors.green : appTheme.selectScreenCardTextColor,
                                                              ),
                                                              borderRadius: BorderRadius.circular(3)
                                                            ),
                                                            child: Row(
                                                              spacing: 4,
                                                              children: [
                                                                Icon(
                                                                  server.isConnected ? Icons.circle : Icons.power_off,
                                                                  color: server.isConnected ? Colors.green : appTheme.selectScreenCardTextColor,
                                                                  size: server.isConnected ? 8 : 12.5,
                                                                ),
                                                                Text(
                                                                  server.isConnected ? "connected" : "not connected",
                                                                  style: TextStyle(
                                                                    fontSize: 10,
                                                                    color: server.isConnected ? Colors.green : appTheme.selectScreenCardTextColor,
                                                                  )
                                                                )
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              }
                                            ),
                                          ),
                                        )
                                      )
                                    ]
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  child: Divider(
                                    color: appTheme.selectScreenCardTextColor,
                                    thickness: 0.2,
                                    indent: 65,
                                    endIndent: 65,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 15),
                                  child: ListTile(
                                    title: Text("Connect to Termux"),
                                    titleTextStyle: TextStyle(
                                      fontSize: 20,
                                      color: appTheme.selectScreenCardTextColor
                                    ),
                                    leading: SvgPicture.asset(
                                      "assets/icons/Termux.svg",
                                      height: 30,
                                      width: 30
                                    ),
                                  ),
                                ),

                                BlocBuilder<TermuxCubit, TermuxState>(
                                  builder: (context, termuxState) {
                                    return Padding(
                                      padding: const EdgeInsets.only(left: 00),
                                      child: Column(
                                        children: [
                                          ListTile(
                                            title: Text("Initial setup"),
                                            leading: Icon(
                                              Icons.settings_input_hdmi_outlined,
                                              color: Colors.lightBlue
                                            ),
                                            titleTextStyle: TextStyle(
                                              color: appTheme.selectScreenCardTextColor,
                                              fontSize: 17
                                            ),
                                            subtitle: Text("The one time setup to connect with Termux"),
                                            onTap: (){
                                              final termFolder = "$appDir/.termux/.ssh";
                                              final termPubKey = File("$termFolder/id_ed25519.pub");
                                              final termPrivKey = File("$termFolder/id_ed25519");
                                              final termxUrlCtrl = TextEditingController()..text = termuxState.termInfo?.username ?? "";
                                              final termxFormKey = GlobalKey<FormState>();
                                              showDialog(
                                                context: context,
                                                builder: (context) => FutureBuilder<int>(
                                                  future: (() async{
                                                    if(!termPubKey.existsSync() || !termPrivKey.existsSync()){
                                                        await SshKeygen(
                                                        comment: "roxum@termux",
                                                        termPubKey: termPubKey,
                                                        termPrivKey: termPrivKey
                                                      ).generate();
                                                      return 0;
                                                    }
                                                    return 1;
                                                  })(),
                                                  
                                                  builder: (context, asyncSnapshot) {
                                                    if(asyncSnapshot.connectionState == .waiting){
                                                      return Center(child: CircularProgressIndicator());
                                                    } else if (asyncSnapshot.hasError) {
                                                      return Text(
                                                        "Failed to generate keys for termux",
                                                        style: TextStyle(
                                                          color: appTheme.selectScreenCardTextColor,
                                                          fontSize: 20
                                                        )
                                                      );
                                                    }
                                          
                                                    return StatefulBuilder(
                                                      builder:(context, setTState) => Dialog(
                                                        constraints: BoxConstraints(
                                                          maxHeight: 700
                                                        ),
                                                        backgroundColor: appTheme.selectScreenCardsBg,
                                                        child: DefaultTextStyle(
                                                          style: TextStyle(
                                                            color: appTheme.selectScreenCardTextColor,
                                                            fontSize: 18
                                                          ),
                                                          child: Padding(
                                                            padding: const EdgeInsets.all(18),
                                                            child: Scrollbar(
                                                              child: ListView(
                                                                children: [
                                                                  const Padding(
                                                                    padding: EdgeInsets.only(bottom: 20),
                                                                    child: Center(child: Text("First time setup")),
                                                                  ),
                                                                  const Text("1. Install OpenSSH"),
                                                                  Padding(
                                                                    padding: const EdgeInsets.symmetric(vertical: 20),
                                                                    child: copyArea(
                                                                      context,
                                                                      appTheme,
                                                                      "pkg install openssh",
                                                                      50
                                                                    ),
                                                                  ),
                                                                                                        
                                                                  const Text("2. Paste the below command"),
                                                                  Padding(
                                                                    padding: const EdgeInsets.symmetric(vertical: 20),
                                                                    child: copyArea(
                                                                      context,
                                                                      appTheme,
                                                                      "mkdir -p ~/.ssh\n\n"
                                                                      "chmod 700 ~/.ssh\n\n"
                                                                      "echo \"${termPubKey.readAsStringSync()}\" >> ~/.ssh/authorized_keys\n\n"
                                                                      "chmod 600 ~/.ssh/authorized_keys",
                                                                      250
                                                                    ),
                                                                  ),

                                                                  const Text("3. Setup storage access"),
                                                                  Padding(
                                                                    padding: const EdgeInsets.symmetric(vertical: 20),
                                                                    child: copyArea(
                                                                      context,
                                                                      appTheme,
                                                                      "termux-setup-storage",
                                                                      50
                                                                    ),
                                                                  ),
                                                                                                        
                                                                  const Text("4. Get the username"),
                                                                  Padding(
                                                                    padding: const EdgeInsets.only(top: 20),
                                                                    child: copyArea(
                                                                      context,
                                                                      appTheme,
                                                                      "whoami",
                                                                      50
                                                                    ),
                                                                  ),
                                          
                                                                  Padding(
                                                                    padding: const EdgeInsets.only(left: 10, top: 3.5, bottom: 20),
                                                                    child: Text(
                                                                      "eg output: u0_a399",
                                                                      style: TextStyle(
                                                                        fontSize: 14
                                                                      )
                                                                    ),
                                                                  ),
                                          
                                                                  const Text("5. Paste the username here"),
                                                                  Padding(
                                                                    padding: const EdgeInsets.symmetric(vertical: 20),
                                                                    child: Form(
                                                                      key: termxFormKey,
                                                                      child: settingsTextField(
                                                                        termxUrlCtrl,
                                                                        Icons.person,
                                                                        "Termux username",
                                                                        appTheme.selectScreenCardTextColor,
                                                                        "eg: u0_a399",
                                                                        (val) => val == null || val.isEmpty || !val.startsWith("u") ? "Enter a valid username" : null
                                                                      ),
                                                                    ),
                                                                  ),

                                                                  ElevatedButton(
                                                                    style: ElevatedButton.styleFrom(
                                                                      backgroundColor: appTheme.scaffoldBg,
                                                                      foregroundColor: Colors.white,
                                                                      shape: RoundedRectangleBorder(
                                                                        borderRadius: .circular(10),
                                                                        side: BorderSide(
                                                                          color: Colors.blue
                                                                        )
                                                                      )
                                                                    ),
                                                                    onPressed: () async{
                                                                      if(termxFormKey.currentState!.validate()){
                                                                        final server = SSHPrivateKey(
                                                                          name: "Termux",
                                                                          id: DateTime.now().millisecondsSinceEpoch,
                                                                          url: "ssh://${termxUrlCtrl.text}@localhost:8022"
                                                                        );
                                          
                                                                        context.read<TermuxCubit>().setTermuxInfo(server);
                                                                        Navigator.pop(context);
                                                                        if(termuxState.termInfo != null){
                                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                                            SnackBar(
                                                                              backgroundColor: Colors.green,
                                                                              content: Text(
                                                                                "Successfully saved.\nGo to the next step to connect with Termux.",
                                                                                style: TextStyle(
                                                                                  color: Colors.white
                                                                                )
                                                                              )
                                                                            )
                                                                          );
                                                                        }
                                                                      }
                                                                      
                                                                    },
                                                                    child: Row(
                                                                      mainAxisAlignment: .center,
                                                                      children: [
                                                                        Icon(Icons.save),
                                                                        Text("Save"),
                                                                      ],
                                                                    )
                                                                  )
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                ),
                                              );
                                            },
                                          ),

                                          ListTile(
                                            title: Row(
                                              spacing: 3.5,
                                              children: [
                                                if(termuxState.termInfo?.isConnected ?? false) Icon(
                                                  Icons.circle,
                                                  color: Colors.green,
                                                  size: 10
                                                ),
                                                Text(termuxState.termInfo?.isConnected ?? false ? "Connected" : "Connect"),
                                              ],
                                            ),
                                            titleTextStyle: TextStyle(
                                              color: termuxState.termInfo?.isConnected ?? false ? Colors.green : appTheme.selectScreenCardTextColor,
                                              fontSize: 17
                                            ),
                                            subtitle: Text("Establish connection after completing the initial setup."),
                                            leading: Icon(
                                              Icons.power,
                                              color: termuxState.termInfo?.isConnected ?? false ? Colors.green : Colors.lightBlue
                                            ),
                                            onTap: () {
                                              showDialog(
                                                context: context,
                                                builder:(context) => StatefulBuilder(
                                                  builder: (context, setTState) => Dialog(
                                                    constraints: BoxConstraints(maxHeight: 330),
                                                    backgroundColor: appTheme.selectScreenCardsBg,
                                                    child: DefaultTextStyle(
                                                      style: TextStyle(
                                                        color: appTheme.selectScreenCardTextColor,
                                                        fontSize: 18
                                                      ),
                                                      child: Padding(
                                                        padding: const EdgeInsets.all(20),
                                                        child: Column(
                                                          spacing: 20,
                                                          crossAxisAlignment: .start,
                                                          children: [
                                                            Container(
                                                              padding: EdgeInsets.all(8),
                                                              decoration: BoxDecoration(
                                                                borderRadius: .circular(10),
                                                                border: .all(
                                                                  color: Colors.blue
                                                                )
                                                              ),
                                                              child: Row(
                                                                spacing: 5,
                                                                children: [
                                                                  Icon(
                                                                    Icons.info_outline,
                                                                    color: Colors.blue,
                                                                    size: 15
                                                                  ),
                                                                  Expanded(
                                                                    child: Text(
                                                                      "Make sure to complete the one time setup.",
                                                                      style: TextStyle(
                                                                        fontSize: 14
                                                                      )
                                                                    ),
                                                                  ),
                                                                ],
                                                              )
                                                            ),
                                                        
                                                            Text("1. Start the ssh server in Termux."),
                                                            copyArea(
                                                              context,
                                                              appTheme,
                                                              "sshd",
                                                              50
                                                            ),

                                                            Text("2. Connect"),
                                                            ElevatedButton(
                                                              style: ElevatedButton.styleFrom(
                                                                backgroundColor: termuxState.termInfo?.isConnected ?? false ? Colors.green : appTheme.scaffoldBg,
                                                                foregroundColor: Colors.white,
                                                                shape: RoundedRectangleBorder(
                                                                  borderRadius: .circular(10),
                                                                  side: BorderSide(
                                                                    color: Colors.green
                                                                  )
                                                                )
                                                              ),
                                                              onPressed: () async{
                                                                SSHPrivateKey? server = termuxState.termInfo;
                                                                final SSHPrivateKey? newServer;
                                                                if(server == null){
                                                                  newServer = await TermuxCubit.getSavedTermuxInfo();
                                                                  if(newServer == null){
                                                                    if(!context.mounted) return;
                                                                    showDialog(
                                                                      context: context,
                                                                      builder:(context) => AlertDialog(
                                                                        backgroundColor: appTheme.selectScreenCardsBg,
                                                                        title: Text("Failed to connect !"),
                                                                        titleTextStyle: TextStyle(
                                                                          color: appTheme.selectScreenCardTextColor,
                                                                          fontSize: 18
                                                                        ),
                                                                        contentTextStyle: TextStyle(
                                                                          color: appTheme.selectScreenCardTextColor,
                                                                          fontSize: 15
                                                                        ),
                                                                        content: Text("Please complete the initial setup."),
                                                                        icon: Icon(
                                                                          Icons.error,
                                                                          size: 35
                                                                        ),
                                                                        iconColor: Colors.red,
                                                                        actionsAlignment: .center,
                                                                        actions: [
                                                                          ElevatedButton(
                                                                            style: ElevatedButton.styleFrom(
                                                                              shape: RoundedRectangleBorder(
                                                                                borderRadius: .circular(10)
                                                                              )
                                                                            ),
                                                                            onPressed: () => Navigator.pop(context),
                                                                            child: Text("Ok")
                                                                          )
                                                                        ],
                                                                      ),
                                                                    );
                                                                    return;
                                                                  } else if(!context.mounted){
                                                                    return;
                                                                  } else{
                                                                    context.read<TermuxCubit>().setTermuxInfo(newServer);
                                                                    server = newServer;
                                                                  }
                                                                }

                                                                if(server.isConnected) {
                                                                  showDialog(
                                                                    context: context,
                                                                    builder: (context) => StatefulBuilder(
                                                                      builder: (context, _) {
                                                                        return AlertDialog(
                                                                          backgroundColor: appThemeState.appTheme.isDark ? appThemeState.appTheme.scaffoldBg : null,
                                                                          title: Text(
                                                                            'Disconnect Termux?',
                                                                            style: TextStyle(
                                                                              color: appThemeState.appTheme.selectScreenCardTextColor,
                                                                              fontSize: 20
                                                                            ),
                                                                          ),
                                                                          content: Text(
                                                                            "Are you sure you want to disconnect from termux?",
                                                                            style: TextStyle(
                                                                              color: appThemeState.appTheme.selectScreenCardTextColor.withAlpha(150),
                                                                              fontSize: 16
                                                                            )
                                                                          ),
                                                                          actions: [
                                                                            ElevatedButton(
                                                                              style: ElevatedButton.styleFrom(
                                                                                shape: RoundedRectangleBorder(
                                                                                  borderRadius: .circular(10)
                                                                                ),
                                                                              ),
                                                                              onPressed: () => Navigator.of(context).pop(),
                                                                              child: Text('Cancel')
                                                                            ),
                                                                            ElevatedButton(
                                                                              onPressed: () {
                                                                                server!.disconnect();
                                                                                context.read<TermuxCubit>().unSetTermuxInfo();
                                                                                Navigator.of(context).pop();
                                                                                Navigator.of(context).pop();
                                                                              },
                                                                              style: ElevatedButton.styleFrom(
                                                                                shape: RoundedRectangleBorder(
                                                                                  borderRadius: .circular(10)
                                                                                ),
                                                                                backgroundColor: Colors.red
                                                                              ),
                                                                              child: Text('Disconnect', style: TextStyle(color: Colors.white))
                                                                            )
                                                                          ],
                                                                        );
                                                                      }
                                                                    )
                                                                  );
                                                                  return;
                                                                }

                                                                final result = await server.connect();

                                                                if(context.mounted){
                                                                  Navigator.pop(context);
                                                                  context.read<TermuxCubit>().setTermuxInfo(server);
                                                                  if(result.$1) {
                                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                                      SnackBar(
                                                                        backgroundColor: Colors.green,
                                                                        content: Text(
                                                                          result.$2,
                                                                          style: TextStyle(
                                                                            color: Colors.white
                                                                          )
                                                                        )
                                                                      )
                                                                    );
                                                                  } else if(result.$2.startsWith("Server unreachable")){
                                                                    showDialog(
                                                                      context: context,
                                                                      builder:(context) => AlertDialog(
                                                                        backgroundColor: appThemeState.appTheme.isDark ? const Color(0xff181A26) : null,
                                                                        icon: Icon(Icons.error, size: 30),
                                                                        iconColor: Colors.red,
                                                                        title: Text("Failed to connect !"),
                                                                        titleTextStyle: TextStyle(
                                                                          color: appTheme.selectScreenCardTextColor,
                                                                          fontSize: 22
                                                                        ),
                                                                        content: Padding(
                                                                          padding: const EdgeInsets.only(left: 15),
                                                                          child: RichText(
                                                                            text: TextSpan(
                                                                              style: TextStyle(
                                                                                color: appTheme.selectScreenCardTextColor
                                                                              ),
                                                                              children: [
                                                                                TextSpan(
                                                                                  text: "Please run "
                                                                                ),
                                                                                WidgetSpan(
                                                                                  child: Container(
                                                                                    padding: EdgeInsets.symmetric(horizontal: 3.5),
                                                                                    decoration: BoxDecoration(
                                                                                      color: Colors.white.withAlpha(50),
                                                                                      borderRadius: .circular(5)
                                                                                    ),
                                                                                    child: Text(
                                                                                      "sshd",
                                                                                      style: TextStyle(
                                                                                        color: appTheme.selectScreenCardTextColor
                                                                                      )
                                                                                    )
                                                                                  ),
                                                                                ),
                                                                                TextSpan(text: " in termux")
                                                                              ]
                                                                            )
                                                                          ),
                                                                        ),
                                                                        actionsAlignment: .center,
                                                                        actions: [
                                                                          ElevatedButton(
                                                                            onPressed: () {
                                                                              server!.disconnect();
                                                                              context.read<TermuxCubit>().unSetTermuxInfo();
                                                                              Navigator.of(context).pop();
                                                                            },
                                                                            style: ElevatedButton.styleFrom(
                                                                              backgroundColor: Colors.white,
                                                                              shape: RoundedRectangleBorder(
                                                                                borderRadius: .circular(10)
                                                                              )
                                                                            ),
                                                                            child: Text('OK')
                                                                          )
                                                                        ]
                                                                      ),
                                                                    );
                                                                  } else {
                                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                                      SnackBar(
                                                                        backgroundColor: Colors.red,
                                                                        content: Text(
                                                                          result.$2,
                                                                          style: TextStyle(
                                                                            color: Colors.white
                                                                          )
                                                                        )
                                                                      )
                                                                    );
                                                                  }
                                                                }
                                                              },
                                                              child: Row(
                                                                spacing: 5,
                                                                mainAxisAlignment: .center,
                                                                children: [
                                                                  Icon(Icons.power),
                                                                  Text(
                                                                    termuxState.termInfo?.isConnected ?? false ? "Connected" : "Connect"
                                                                  )
                                                                ],
                                                              )
                                                            )
                                                          ]
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),

                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 35),
                      settingsDivider,
                      const SizedBox(height: 20),
                      settingsType("AI Configuration", appThemeState.appTheme.isDark),
                      BlocBuilder<AIBloc, AIState>(
                        builder: (context, aiState) {
                          final copilotState = context.watch<CopilotBloc>().state;
                          final hasAI = aiState.config.isNotEmpty || copilotState.status == CopilotStatus.signedIn;
                          return Column(
                            spacing: 10,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              BlocBuilder<CopilotBloc, CopilotState>(
                                builder: (context, copilotState) {
                                  return _buildCopilotButton(context, copilotState, appThemeState);
                                },
                              ),
                              const SizedBox(height: 5),
                              SizedBox(
                                width: 280,
                                height: 45,
                                child: ElevatedButton(
                                    onPressed: (){
                                      String? provider;
                                      String customHttpMethod = 'POST';
                                      String customToolCallingMethod = 'openAiCompatible';
                                      final customUrlController = TextEditingController();
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return StatefulBuilder(
                                            builder: (context, setDialogState) {
                                              final isCustomProvider = provider == 'Custom';
                                              return Dialog(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                backgroundColor: appThemeState.appTheme.isDark ? const Color(0xff181A26) : Colors.white,
                                                child: Container(
                                                  width: 400,
                                                  padding: const EdgeInsets.all(20),
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(20),
                                                    gradient: LinearGradient(
                                                      colors: appThemeState.appTheme.isDark
                                                        ? [const Color(0xff181A26), const Color(0xff1e1f2b)]
                                                        : [Colors.white, Colors.grey[100]!],
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                    ),
                                                  ),
                                                  child: Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Icon(Icons.smart_toy, color: Colors.lightBlue, size: 30),
                                                          const SizedBox(width: 10),
                                                          Text(
                                                            'Create a completion model',
                                                            style: TextStyle(
                                                              color: appThemeState.appTheme.selectScreenCardTextColor,
                                                              fontSize: 18,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 20),
                                                      Form(
                                                        key: _formKey,
                                                        child: Column(
                                                          children: [
                                                            DropdownButtonFormField<String>(
                                                              initialValue: provider,
                                                              dropdownColor: appThemeState.appTheme.isDark ? const Color(0xff181A26) : Colors.white,
                                                              hint: Text(
                                                                "Select a Provider",
                                                                style: TextStyle(
                                                                  color: appThemeState.appTheme.selectScreenCardTextColor.withAlpha(150),
                                                                ),
                                                              ),
                                                              decoration: InputDecoration(
                                                                prefixIcon: Icon(Icons.business, color: Colors.lightBlue),
                                                                border: OutlineInputBorder(
                                                                  borderRadius: BorderRadius.circular(15)
                                                                ),
                                                                focusedBorder: OutlineInputBorder(
                                                                  borderRadius: BorderRadius.circular(15),
                                                                  borderSide: BorderSide(
                                                                    color: Colors.lightBlue,
                                                                    width: 2,
                                                                  )
                                                                ),
                                                              ),
                                                              items: List.generate(
                                                                models.length,
                                                                (index) => DropdownMenuItem(
                                                                  value: models[index],
                                                                  child: Text(
                                                                    models[index],
                                                                    style: TextStyle(
                                                                      color: appThemeState.appTheme.selectScreenCardTextColor
                                                                    ),
                                                                  )
                                                                )
                                                              ),
                                                              onChanged: (val){
                                                                setDialogState(() {
                                                                  provider = val;
                                                                });
                                                              },
                                                              validator: (value) => value == null ? "Select a valid provider" : null,
                                                            ),
                                                            const SizedBox(height: 15),
                                                            settingsTextField(
                                                              modelNameController,
                                                              Icons.label,
                                                              "Model name",
                                                              appThemeState.appTheme.selectScreenCardTextColor,
                                                              "model name as per the provider's api",
                                                              (value) => value == null || value.isEmpty ? "Enter a valid model name" : null,
                                                            ),
                                                            const SizedBox(height: 15),
                                                            settingsTextField(
                                                              apiController,
                                                              Icons.key,
                                                              "API Key",
                                                              appThemeState.appTheme.selectScreenCardTextColor,
                                                              isCustomProvider
                                                                ? "Optional: Bearer token for the custom endpoint"
                                                                : "API key for the corresponding provider",
                                                              (value) {
                                                                if (isCustomProvider) {
                                                                  return null;
                                                                }
                                                                return value == null || value.isEmpty ? "Enter a valid API key" : null;
                                                              }
                                                            ),
                                                            if (isCustomProvider) ...[
                                                              const SizedBox(height: 15),
                                                              settingsTextField(
                                                                customUrlController,
                                                                Icons.link,
                                                                "Custom Endpoint URL",
                                                                appThemeState.appTheme.selectScreenCardTextColor,
                                                                "https://api.example.com/v1/chat/completions",
                                                                (value) {
                                                                  if (!isCustomProvider) return null;
                                                                  if (value == null || value.trim().isEmpty) {
                                                                    return "Enter a valid endpoint URL";
                                                                  }
                                                                  final uri = Uri.tryParse(value.trim());
                                                                  if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
                                                                    return "Enter a valid absolute URL";
                                                                  }
                                                                  return null;
                                                                }
                                                              ),
                                                              const SizedBox(height: 15),
                                                              DropdownButtonFormField<String>(
                                                                initialValue: customHttpMethod,
                                                                dropdownColor: appThemeState.appTheme.isDark ? const Color(0xff181A26) : Colors.white,
                                                                decoration: InputDecoration(
                                                                  prefixIcon: Icon(Icons.http, color: Colors.lightBlue),
                                                                  border: OutlineInputBorder(
                                                                    borderRadius: BorderRadius.circular(15),
                                                                  ),
                                                                  focusedBorder: OutlineInputBorder(
                                                                    borderRadius: BorderRadius.circular(15),
                                                                    borderSide: BorderSide(
                                                                      color: Colors.lightBlue,
                                                                      width: 2,
                                                                    ),
                                                                  ),
                                                                ),
                                                                items: [
                                                                  DropdownMenuItem(value: 'POST', child: Text('POST', style: TextStyle(color: appThemeState.appTheme.selectScreenCardTextColor))),
                                                                  DropdownMenuItem(value: 'GET', child: Text('GET', style: TextStyle(color: appThemeState.appTheme.selectScreenCardTextColor))),
                                                                ],
                                                                onChanged: (value) {
                                                                  if (value == null) return;
                                                                  setDialogState(() {
                                                                    customHttpMethod = value;
                                                                  });
                                                                },
                                                              ),
                                                              const SizedBox(height: 15),
                                                              DropdownButtonFormField<String>(
                                                                initialValue: customToolCallingMethod,
                                                                dropdownColor: appThemeState.appTheme.isDark ? const Color(0xff181A26) : Colors.white,
                                                                decoration: InputDecoration(
                                                                  prefixIcon: Icon(Icons.hub_outlined, color: Colors.lightBlue),
                                                                  labelText: 'Agentic Tool Protocol',
                                                                  labelStyle: TextStyle(
                                                                    color: appThemeState.appTheme.selectScreenCardTextColor.withAlpha(150),
                                                                    fontSize: 15,
                                                                  ),
                                                                  border: OutlineInputBorder(
                                                                    borderRadius: BorderRadius.circular(15),
                                                                  ),
                                                                  focusedBorder: OutlineInputBorder(
                                                                    borderRadius: BorderRadius.circular(15),
                                                                    borderSide: BorderSide(
                                                                      color: Colors.lightBlue,
                                                                      width: 2,
                                                                    ),
                                                                  ),
                                                                ),
                                                                items: [
                                                                  DropdownMenuItem(
                                                                    value: 'openAiCompatible',
                                                                    child: Text('OpenAI-compatible', style: TextStyle(color: appThemeState.appTheme.selectScreenCardTextColor)),
                                                                  ),
                                                                  DropdownMenuItem(
                                                                    value: 'anthropicMessages',
                                                                    child: Text('Anthropic Messages', style: TextStyle(color: appThemeState.appTheme.selectScreenCardTextColor)),
                                                                  ),
                                                                  DropdownMenuItem(
                                                                    value: 'geminiFunctionCalling',
                                                                    child: Text('Gemini Function Calling', style: TextStyle(color: appThemeState.appTheme.selectScreenCardTextColor)),
                                                                  ),
                                                                  DropdownMenuItem(
                                                                    value: 'none',
                                                                    child: Text('None (disable agentic tools)', style: TextStyle(color: appThemeState.appTheme.selectScreenCardTextColor)),
                                                                  ),
                                                                ],
                                                                onChanged: (value) {
                                                                  if (value == null) return;
                                                                  setDialogState(() {
                                                                    customToolCallingMethod = value;
                                                                  });
                                                                },
                                                              ),
                                                            ],
                                                            const SizedBox(height: 15),
                                                            Divider(color: Colors.lightBlue.withAlpha(100)),
                                                            const SizedBox(height: 15),
                                                            TextField(
                                                              style: TextStyle(
                                                                color: appThemeState.appTheme.selectScreenCardTextColor
                                                              ),
                                                              controller: modelIdController,
                                                              cursorColor: Colors.lightBlue,
                                                              decoration: InputDecoration(
                                                                prefixIcon: Icon(Icons.tag, color: Colors.lightBlue),
                                                                hintText: "A unique nick name, leave it empty to generate one",
                                                                hintStyle: TextStyle(
                                                                  color: Colors.grey,
                                                                  fontSize: 12
                                                                ),
                                                                border: OutlineInputBorder(
                                                                  borderRadius: BorderRadius.circular(15)
                                                                ),
                                                                focusedBorder: OutlineInputBorder(
                                                                  borderRadius: BorderRadius.circular(15),
                                                                  borderSide: BorderSide(
                                                                    color: Colors.lightBlue,
                                                                    width: 2,
                                                                  )
                                                                ),
                                                                labelText: "Nick Name (Optional)",
                                                                labelStyle: TextStyle(
                                                                  color: appThemeState.appTheme.selectScreenCardTextColor.withAlpha(150),
                                                                  fontSize: 15
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(height: 20),
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.end,
                                                        children: [
                                                          TextButton(
                                                            onPressed: () => Navigator.of(context).pop(),
                                                            style: TextButton.styleFrom(
                                                              foregroundColor: Colors.grey,
                                                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                                            ),
                                                            child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                                                          ),
                                                          const SizedBox(width: 10),
                                                          ElevatedButton(
                                                            onPressed: () async {
                                                              final prefs = await SharedPreferences.getInstance();
                                                              if (_formKey.currentState!.validate()) {
                                                                final selectedProvider = provider;
                                                                if (selectedProvider == null) {
                                                                  return;
                                                                }
                                                                final modelName = modelNameController.text.trim();
                                                                final apiKey = apiController.text.trim();
                                                                final modelId = (() {
                                                                  final modelId = modelIdController.text.trim();
                                                                  if (modelId.isEmpty) {
                                                                    return "$modelName-${DateTime.now().millisecondsSinceEpoch}";
                                                                  }
                                                                  return modelId;
                                                                })();
                                                                final aiConfig = {
                                                                  modelId: {
                                                                    "provider": selectedProvider,
                                                                    "apiProvider": selectedProvider,
                                                                    "modelName": modelName,
                                                                    "model": modelName,
                                                                    "apiKey": apiKey,
                                                                    if (selectedProvider == 'Custom') ...{
                                                                      "url": customUrlController.text.trim(),
                                                                      "httpMethod": customHttpMethod,
                                                                      "toolCallingMethod": customToolCallingMethod,
                                                                    },
                                                                  }
                                                                };
                                                                final newConfig = Map<String, dynamic>.from(aiState.config)..addAll(aiConfig);
                                                                await prefs.setString('aiConfig', jsonEncode(newConfig));
                                                                if (context.mounted) {
                                                                  context.read<AIBloc>().add(AIConfigEvent(newConfig));
                                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                                    SnackBar(content: Text("Successfully created model $modelName"))
                                                                  );
                                                                  Navigator.of(context).pop();
                                                                }
                                                              }
                                                            },
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor: Colors.lightBlue,
                                                              foregroundColor: Colors.white,
                                                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(10),
                                                              ),
                                                            ),
                                                            child: const Text('Create', style: TextStyle(fontSize: 16)),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        }
                                      );
                                    },
                                    style: ButtonStyle(
                                      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                      backgroundColor: WidgetStatePropertyAll(Colors.lightBlue),
                                    ),
                                    child: Row(
                                      spacing: 7.5,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add, color: Colors.white, size: 20),
                                        Text(
                                          "Create an AI model",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.bold
                                          ),
                                        )
                                      ],
                                    )
                                  ),
                              ),
                              
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                child: SizedBox(
                                  width: 280,
                                  height: 45,
                                  child: ElevatedButton(
                                    style: ButtonStyle(
                                      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                      backgroundColor: WidgetStatePropertyAll(Colors.lightBlue),
                                      foregroundColor: WidgetStatePropertyAll(Colors.white),
                                    ),
                                    onPressed: () {
                                      final models = _ggufModels.map((m) => GgufModel(
                                        name: m['name']!,
                                        url: m['url']!,
                                        fileName: m['filename']!,
                                        paramSize: (m['param-size']! as num).toDouble(),
                                        quant: m['quant']!,
                                        imageUrl: m['image-url']!
                                      )).toList();
                                      showDialog(
                                        context: context,
                                        builder: (_) => GgufDownloadManager(availableModels: models),
                                      );
                                    },
                                    child: Row(
                                      spacing: 8,
                                      mainAxisAlignment: .center,
                                      children: [
                                        Icon(Icons.cloud_download),
                                        Text(
                                          "Download a GGUF model",
                                          style: TextStyle(
                                            fontWeight: .bold,
                                            fontSize: 15
                                          )
                                        )
                                      ],
                                    )
                                  ),
                                ),
                              ),

                              SizedBox(
                                width: 280,
                                height: 45,
                                child: ElevatedButton(
                                  style: ButtonStyle(
                                    shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                    backgroundColor: WidgetStatePropertyAll(Colors.lightBlue),
                                    foregroundColor: WidgetStatePropertyAll(Colors.white),
                                  ),
                                  onPressed: () => _loadLocalGgufModel(context, appThemeState),
                                  child: Row(
                                    spacing: 8,
                                    mainAxisAlignment: .center,
                                    children: [
                                      Icon(Icons.sd_storage),
                                      Text(
                                        "Load a GGUF model",
                                        style: TextStyle(
                                          fontWeight: .bold,
                                          fontSize: 15
                                        )
                                      )
                                    ],
                                  )
                                ),
                              ),

                              Align(
                                alignment: Alignment.center,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: appThemeState.appTheme.isDark ? const Color.fromARGB(255, 35, 37, 54) : Colors.grey[200],
                                    ),
                                    width: 350,
                                    alignment: Alignment.center,
                                    child: Column(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color: appThemeState.appTheme.isDark ? Colors.indigo : const Color.fromARGB(255, 199, 181, 248),
                                            borderRadius: BorderRadius.vertical(top: Radius.circular(10))
                                          ),
                                          alignment: Alignment.centerLeft,
                                          child: Padding(
                                            padding: const EdgeInsets.only(left: 8),
                                            child: Padding(
                                              padding: const EdgeInsets.all(5),
                                              child: Text(
                                                "AI Models",
                                                style: TextStyle(
                                                  color: appThemeState.appTheme.selectScreenCardTextColor,
                                                  fontSize: 13
                                                )
                                              ),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: Builder(builder: (ctx) {
                                            final copilotSignedIn = context.read<CopilotBloc>().state.status == CopilotStatus.signedIn;
                                            if (!copilotSignedIn && aiState.config.isEmpty) {
                                              return Text(
                                                "No models have been created yet",
                                                style: TextStyle(
                                                  color: appThemeState.appTheme.selectScreenCardTextColor.withAlpha(150),
                                                  fontSize: 16
                                                )
                                              );
                                            }

                                            final List<Widget> modelCards = [];
                                            if (copilotSignedIn) {
                                              modelCards.add(Card(
                                                color: appThemeState.appTheme.isDark ? const Color.fromARGB(255, 44, 47, 71) : Colors.grey[200],
                                                child: ListTile(
                                                  dense: true,
                                                  leading: Icon(Icons.cloud, color: appThemeState.appTheme.selectScreenCardTextColor),
                                                  title: Text('Copilot', style: TextStyle(color: appThemeState.appTheme.selectScreenCardTextColor)),
                                                  subtitle: Text('Copilot service (signed in)', style: TextStyle(color: appThemeState.appTheme.selectScreenCardTextColor.withAlpha(150))),
                                                  trailing: null,
                                                ),
                                              ));
                                            }

                                            modelCards.addAll(aiState.config.entries.where((e) => e.value is Map<String, dynamic>).map((e) {
                                              final config = e.value as Map<String, dynamic>;
                                              return Card(
                                                color: appThemeState.appTheme.isDark ? const Color.fromARGB(255, 44, 47, 71) : Colors.grey[200],
                                                child: ListTile(
                                                  dense: true,
                                                  leading: Icon(Icons.model_training_outlined, color: appThemeState.appTheme.selectScreenCardTextColor),
                                                  title: Text(
                                                    config['modelName']?.toString() ?? config['model']?.toString() ?? 'Unknown',
                                                    style: TextStyle(color: appThemeState.appTheme.selectScreenCardTextColor)
                                                  ),
                                                  subtitle: Text(
                                                    e.key,
                                                    style: TextStyle(color: appThemeState.appTheme.selectScreenCardTextColor.withAlpha(150))
                                                  ),
                                                  trailing: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      IconButton(
                                                        tooltip: 'Edit model',
                                                        icon: Icon(Icons.edit, color: Colors.lightBlue),
                                                        onPressed: () async {
                                                          await _showModelDialog(
                                                            context: context,
                                                            aiState: aiState,
                                                            appThemeState: appThemeState,
                                                            editingModelId: e.key,
                                                            existingConfig: config,
                                                          );
                                                        },
                                                      ),
                                                      IconButton(
                                                        icon: Icon(Icons.delete, color: Colors.red),
                                                        onPressed: () async {
                                                          showDialog(
                                                            context: context,
                                                            builder: (context) => AlertDialog(
                                                              backgroundColor: appThemeState.appTheme.isDark ? const Color(0xff181A26) : null,
                                                              title: Text(
                                                                'Delete model ${e.key}?',
                                                                style: TextStyle(
                                                                  color: appThemeState.appTheme.selectScreenCardTextColor,
                                                                  fontSize: 20,
                                                                ),
                                                              ),
                                                              content: Text(
                                                                'Are you sure you want to delete this model? This action cannot be undone.',
                                                                style: TextStyle(
                                                                  color: appThemeState.appTheme.selectScreenCardTextColor.withAlpha(150),
                                                                  fontSize: 16,
                                                                ),
                                                              ),
                                                              actions: [
                                                                ElevatedButton(
                                                                  onPressed: () => Navigator.of(context).pop(),
                                                                  child: Text('Cancel'),
                                                                ),
                                                                ElevatedButton(
                                                                  onPressed: () async {
                                                                    final updatedConfig = Map<String, dynamic>.from(aiState.config)..remove(e.key);
                                                                    final prefs = await SharedPreferences.getInstance();
                                                                    await prefs.setString('aiConfig', jsonEncode(updatedConfig));

                                                                    final updatedModelSelected = Map<String, dynamic>.from(aiState.modelSelected);
                                                                    var modelSelectionChanged = false;
                                                                    if (updatedModelSelected['code'] == e.key) {
                                                                      updatedModelSelected['code'] = '';
                                                                      modelSelectionChanged = true;
                                                                    }
                                                                    if (updatedModelSelected['chat'] == e.key) {
                                                                      updatedModelSelected['chat'] = '';
                                                                      modelSelectionChanged = true;
                                                                      await prefs.remove('ai_selected_chat_model_id');
                                                                    }
                                                                    if (modelSelectionChanged) {
                                                                      await prefs.setString('modelSelected', jsonEncode(updatedModelSelected));
                                                                    }

                                                                    if (context.mounted) {
                                                                      context.read<AIBloc>().add(AIConfigEvent(updatedConfig));
                                                                      if (modelSelectionChanged) {
                                                                        context.read<AIBloc>().add(ModelSelectEvent(updatedModelSelected));
                                                                      }
                                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                                        SnackBar(content: Text('Successfully deleted model ${e.key}')),
                                                                      );
                                                                      Navigator.of(context).pop(true);
                                                                    }
                                                                  },
                                                                  style: ButtonStyle(
                                                                    backgroundColor: WidgetStateProperty.all<Color>(Colors.red),
                                                                  ),
                                                                  child: Text('Delete', style: TextStyle(color: Colors.white)),
                                                                )
                                                              ],
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }));

                                            return Column(children: modelCards);
                                          })
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              settingsTile(
                                null,
                                "Enable AI completion",
                                Icon(
                                  Icons.lightbulb,
                                  color: appThemeState.appTheme.selectScreenCardTextColor,
                                  size: 19
                                ),
                                appThemeState.appTheme.isDark,
                                isEnabled: hasAI,
                                trailing: SizedBox(
                                  height: 30,
                                  width: 55,
                                  child: FlutterSwitch(
                                    toggleColor: Color(0xff002b6e),
                                    inactiveToggleColor: Colors.white,
                                    activeColor: Color(0xffb0c6fe),
                                    value: hasAI && aiState.isEnabled,
                                    onToggle: (value) async{
                                      if(hasAI){
                                        final prefs = await SharedPreferences.getInstance();
                                        if(context.mounted){
                                          final currentValue = configState.codeForgeConfig;
                                          currentValue['isAIEnabled'] = value;
                                          prefs.setString('codeForgeConfig', jsonEncode(currentValue));
                                          context.read<AIBloc>().add(AIEnableEvent(value));
                                        }
                                      }
                                      else{
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text("No AI models created and not signed into Copilot. Please create a model or sign into Copilot first."))
                                        );
                                      }
                                    }
                                  ),
                                ),
                              ),
                              settingsTile(
                                null,
                                "Manual completion",
                                Icon(
                                  Icons.touch_app_rounded,
                                  color: appThemeState.appTheme.selectScreenCardTextColor,
                                ),
                                appThemeState.appTheme.isDark,
                                trailing: SizedBox(
                                  height: 30,
                                  width: 55,
                                  child: FlutterSwitch(
                                    toggleColor: Color(0xff002b6e),
                                    inactiveToggleColor: Colors.white,
                                    activeColor: Color(0xffb0c6fe),
                                    value: hasAI && aiState.showSuggestionOntap && aiState.isEnabled,
                                    onToggle: (val) async{
                                      if(hasAI){
                                        final prefs = await SharedPreferences.getInstance();
                                        if(context.mounted){
                                          context.read<AIBloc>().add(AIModeEvent(val));
                                          final currentState = configState.codeForgeConfig;
                                          currentState['manualCompletion'] = val;
                                          prefs.setString('codeForgeConfig', jsonEncode(currentState));
                                        }
                                      }
                                      else{
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text("No AI models created and not signed into Copilot. Please create a model or sign into Copilot first."))
                                        );
                                      }
                                    }
                                  ),
                                ),
                                subTitle: aiState.showSuggestionOntap ? "Tap AI icon for suggestions\nLower API usage"
                                : "Auto-suggest after 1.5s pause\nHigher API usage",
                              ),
                              settingsTile(
                                () async{
                                  if(aiState.config.isEmpty){
                                    final prefs = await SharedPreferences.getInstance();
                                    if(context.mounted){
                                      prefs.setString('modelSelected', jsonEncode({}));
                                      context.read<AIBloc>().add(ModelSelectEvent({}));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("No AI models created yet. Please create a model first."))
                                      );
                                    }
                                  }
                                  else{
                                    showDialog(
                                      context: context,
                                      builder: (contex) => AlertDialog(
                                        backgroundColor: appThemeState.appTheme.isDark ? const Color(0xff181A26) : null,
                                        title: Card(
                                          color: appThemeState.appTheme.isDark ? const Color.fromARGB(255, 35, 37, 54) : Colors.grey[400],
                                          child: Padding(
                                            padding: const EdgeInsets.all(9),
                                            child: Text(
                                              "Completion Model",
                                              style: TextStyle(
                                                color: appThemeState.appTheme.selectScreenCardTextColor,
                                                fontSize: 20
                                              ),
                                            ),
                                          ),
                                        ),
                                        content: SizedBox(
                                          height: 300,
                                          width: 250,
                                          child: Builder(builder: (ctx) {
                                            final copilotSignedIn = context.read<CopilotBloc>().state.status == CopilotStatus.signedIn;
                                            final initialSelected = (aiState.modelSelected['code'] != null && (aiState.modelSelected['code'] as String).isNotEmpty)
                                                ? aiState.modelSelected['code'] as String
                                                : (copilotSignedIn ? 'copilot' : '');

                                            return RadioGroup<String>(
                                              groupValue: initialSelected,
                                              onChanged: (val) async {
                                                final currentState = aiState.modelSelected;
                                                currentState['code'] = val!;
                                                final prefs = await SharedPreferences.getInstance();
                                                prefs.setString('modelSelected', jsonEncode(currentState));

                                                if (context.mounted) {
                                                  context.read<AIBloc>().add(ModelSelectEvent(currentState));
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text("Successfully selected model $val")),
                                                  );
                                                  Navigator.of(context).pop(true);
                                                }
                                              },
                                              child: ListView(
                                                children: [
                                                  if (copilotSignedIn)
                                                    RadioListTile<String>(
                                                      value: 'copilot',
                                                      title: Text('Copilot'),
                                                      subtitle: Text('Copilot service'),
                                                      activeColor: appThemeState.appTheme.isDark ? const Color(0xffb0c6fe) : const Color(0xff181a26),
                                                    ),
                                                  ...aiState.config.entries.map((entry) => RadioListTile<String>(
                                                        value: entry.key,
                                                        title: Text(entry.key),
                                                        activeColor: appThemeState.appTheme.isDark ? const Color(0xffb0c6fe) : const Color(0xff181a26),
                                                      )),
                                                ],
                                              ),
                                            );
                                          }),
                                        ),
                                      )
                                    );
                                  }
                                },
                                "Select completion model",
                                Icon(
                                  Icons.chrome_reader_mode_outlined,
                                  color: appThemeState.appTheme.selectScreenCardTextColor,
                                  size: 19
                                ),
                                appThemeState.appTheme.isDark,
                                subTitle: aiState.modelSelected['code'],
                              ),
                              settingsDivider
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      settingsType("LSP Configuration", appThemeState.appTheme.isDark),
                      settingsTile(
                        null,
                        "Enable LSP support",
                        Icon(
                          Icons.electrical_services_rounded,
                          color: appThemeState.appTheme.selectScreenCardTextColor,
                        ),
                        subTitle: "Provides features like code suggestions, hover details, intelligent highlighting, etc.\nNote: LSP support is limited to a few languages only.",
                        appThemeState.appTheme.isDark,
                        trailing: SizedBox(
                          height: 30,
                          width: 55,
                          child: FlutterSwitch(
                            toggleColor: Color(0xff002b6e),
                            inactiveToggleColor: Colors.white,
                            activeColor: Color(0xffb0c6fe),
                            value: configState.codeForgeConfig['enableLSP'] ?? true,
                            onToggle: (val) async {
                              final prefs = await SharedPreferences.getInstance();
                              if(context.mounted){
                                final currentConfig = configState.codeForgeConfig;
                                currentConfig['enableLSP'] = val;
                                context.read<ConfigBloc>().add(ChangeConfigEvent(currentConfig));
                                prefs.setString('codeForgeConfig', jsonEncode(currentConfig));
                              }
                            }
                          ),
                        ),
                      ),
                      settingsTile(
                        () {
                          final Map<String, dynamic> currentFeatureToggle = Map<String, dynamic>.from(
                            configState.codeForgeConfig["LSPFeatureToggle"] ?? {}
                          );
                          final lspFeatures = [
                            'semanticHighlighting',
                            'codeCompletion',
                            'hoverInfo',
                            'codeAction',
                            'signatureHelp',
                            'documentColor',
                            'documentHighlight',
                            'codeFolding',
                            'inlayHint',
                            'goToDefinition',
                            'rename',
                          ];
                          final featureDisplayNames = {
                            'semanticHighlighting': 'Semantic Highlighting',
                            'codeCompletion': 'Code Completion',
                            'hoverInfo': 'Hover Information',
                            'codeAction': 'Code Actions',
                            'signatureHelp': 'Signature Help',
                            'documentColor': 'Document Color',
                            'documentHighlight': 'Document Highlight',
                            'codeFolding': 'Code Folding',
                            'inlayHint': 'Inlay Hints',
                            'goToDefinition': 'Go to Definition',
                            'rename': 'Rename Symbol',
                          };
                          showDialog(
                            context: context,
                            builder: (context) => StatefulBuilder(
                              builder: (context, setState) {
                                final excludeScrollCtrl = ScrollController();
                                return AlertDialog(
                                  backgroundColor: appThemeState.appTheme.isDark ? const Color(0xff181A26) : Colors.white,
                                  title: Text(
                                    "Configure LSP Features",
                                    style: TextStyle(color: appThemeState.appTheme.selectScreenCardTextColor),
                                  ),
                                  content: SizedBox(
                                    height: 400,
                                    width: 350,
                                    child: RawScrollbar(
                                      thumbVisibility: true,
                                      controller: excludeScrollCtrl,
                                      child: ListView(
                                        controller: excludeScrollCtrl,
                                        children: languages.where((langs) => langs.lspExecutable != null).map((lang) {
                                          final langKey = lang.name.toLowerCase();
                                          final disabledFeatures = List<String>.from(currentFeatureToggle[langKey] ?? []);
                                          final hasDisabledFeatures = disabledFeatures.isNotEmpty;
                                          return Theme(
                                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                            child: ExpansionTile(
                                              tilePadding: EdgeInsets.symmetric(horizontal: 8),
                                              title: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      lang.name,
                                                      style: TextStyle(
                                                        color: appThemeState.appTheme.selectScreenCardTextColor,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                  if (hasDisabledFeatures)
                                                    Container(
                                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: Colors.orange.withValues(alpha: 0.2),
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: Text(
                                                        '${disabledFeatures.length} disabled',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.orange,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              iconColor: appThemeState.appTheme.selectScreenCardTextColor,
                                              collapsedIconColor: appThemeState.appTheme.selectScreenCardTextColor,
                                              children: lspFeatures.map((feature) {
                                                final isDisabled = disabledFeatures.contains(feature);
                                                return CheckboxListTile(
                                                  dense: true,
                                                  title: Text(
                                                    featureDisplayNames[feature] ?? feature,
                                                    style: TextStyle(
                                                      color: appThemeState.appTheme.selectScreenCardTextColor,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  value: isDisabled,
                                                  activeColor: Colors.orange,
                                                  checkColor: Colors.white,
                                                  onChanged: (val) {
                                                    setState(() {
                                                      if (val!) {
                                                        if (!disabledFeatures.contains(feature)) {
                                                          disabledFeatures.add(feature);
                                                        }
                                                      } else {
                                                        disabledFeatures.remove(feature);
                                                      }
                                                      if (disabledFeatures.isEmpty) {
                                                        currentFeatureToggle.remove(langKey);
                                                      } else {
                                                        currentFeatureToggle[langKey] = disabledFeatures;
                                                      }
                                                    });
                                                  },
                                                );
                                              }).toList(),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(
                                        "Cancel",
                                        style: TextStyle(color: appThemeState.appTheme.selectScreenCardTextColor),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        final prefs = await SharedPreferences.getInstance();
                                        final currentConfig = configState.codeForgeConfig;
                                        currentConfig["LSPFeatureToggle"] = currentFeatureToggle;
                                        await prefs.setString('codeForgeConfig', jsonEncode(currentConfig));
                                        if (context.mounted) {
                                          context.read<ConfigBloc>().add(ChangeConfigEvent(currentConfig));
                                          Navigator.pop(context);
                                        }
                                      },
                                      child: Text(
                                        "OK",
                                        style: TextStyle(color: Colors.lightBlue),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          );
                        },
                        "Configure LSP Features",
                        Icon(Icons.tune, color: appThemeState.appTheme.selectScreenCardTextColor, size: 19),
                        appThemeState.appTheme.isDark,
                        subTitle: () {
                          final featureToggle = configState.codeForgeConfig["LSPFeatureToggle"] as Map<String, dynamic>? ?? {};
                          final totalDisabled = featureToggle.values.fold<int>(0, (sum, list) => sum + (list as List).length);
                          if (totalDisabled == 0) return "All features enabled";
                          final langsWithDisabled = featureToggle.keys.length;
                          return "$totalDisabled features disabled across $langsWithDisabled language${langsWithDisabled > 1 ? 's' : ''}";
                        }()
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: settingsDivider,
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
