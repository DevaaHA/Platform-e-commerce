import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final TextEditingController _messageController = TextEditingController();

  // قائمة رسائل المحادثة الحقيقية
  final List<Map<String, dynamic>> _messages = [
    {
      'sender': 'support',
      'text': 'مرحباً بك يا حسام في دعم "سوق جو". كيف يمكننا مساعدتك اليوم؟',
      'time': 'الآن',
    },
  ];

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    String userText = _messageController.text;
    setState(() {
      _messages.add({'sender': 'user', 'text': userText, 'time': 'الآن'});
    });

    _messageController.clear();

    // محاكاة رد آلي ذكي من خدمة العملاء بعد ثانية
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _messages.add({
          'sender': 'support',
          'text':
              'تم استلام استفسارك بنجاح يا حسام، سيتم تحويلك إلى مختص الدعم الفني فوراً.',
          'time': 'الآن',
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          '🎧 خدمة العملاء والدعم الفني',
          style: TextStyle(color: AppTheme.gold, fontSize: 16),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppTheme.gold),
      ),
      body: Column(
        children: [
          // رأس المحادثة الترحيبي
          Container(
            padding: const EdgeInsets.all(12),
            color: AppTheme.surfaceDark.withAlpha(150),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.circle, color: Colors.green, size: 10),
                SizedBox(width: 8),
                Text(
                  'فريق الدعم متواجد على مدار الساعة 🟢',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

          // قائمة الرسائل
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                bool isUser = msg['sender'] == 'user';

                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isUser ? AppTheme.gold : AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isUser ? Colors.transparent : Colors.white10,
                      ),
                    ),
                    child: Text(
                      msg['text'],
                      style: TextStyle(
                        color: isUser ? AppTheme.darkBg : Colors.white,
                        fontWeight: isUser
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // شريط إرسال الرسائل السفلي
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              border: const Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'اكتب رسالتك هنا...',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: AppTheme.gold),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
