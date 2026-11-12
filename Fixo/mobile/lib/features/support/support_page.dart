import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/presentation/controllers/auth_controller.dart';
import 'support_repository.dart';

class SupportPage extends ConsumerStatefulWidget {
  const SupportPage({super.key, this.admin = false});
  final bool admin;
  @override
  ConsumerState<SupportPage> createState() => _SupportState();
}

class _SupportState extends ConsumerState<SupportPage> {
  final _text = TextEditingController();
  List<Map<String, dynamic>> _items = [];
  String? _thread, _title, _error;
  bool _busy = false;
  int _epoch = 0;
  bool get ar => Directionality.of(context) == TextDirection.rtl;
  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _epoch++;
    _text.dispose();
    super.dispose();
  }

  void _clearDenied(Object error) {
    if (error is DioException &&
        (error.response?.statusCode == 401 ||
            error.response?.statusCode == 403)) {
      _items = [];
      _thread = null;
      _items = [];
      _title = null;
    }
  }

  Future<void> _load() async {
    final epoch = ++_epoch;
    if (mounted) {
      setState(() {
        _busy = true;
        _error = null;
      });
    }
    try {
      final rows = await ref
          .read(supportRepositoryProvider)
          .list(admin: widget.admin, thread: _thread);
      if (mounted && epoch == _epoch) setState(() => _items = rows);
    } catch (error) {
      if (mounted) setState(() => _clearDenied(error));
      if (mounted && epoch == _epoch) {
        setState(
          () => _error = ar
              ? 'تعذر تحميل المحادثات. حاول مجدداً.'
              : 'Could not load conversations. Please retry.',
        );
      }
    } finally {
      if (mounted && epoch == _epoch) setState(() => _busy = false);
    }
  }

  Future<void> _new() async {
    final subject = TextEditingController();
    final body = TextEditingController();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ar ? 'محادثة جديدة' : 'New conversation'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: subject,
                maxLength: 120,
                decoration: InputDecoration(
                  labelText: ar ? 'الموضوع' : 'Subject',
                ),
              ),
              TextField(
                controller: body,
                maxLength: 2000,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: ar ? 'رسالتك' : 'Message',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(ar ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (subject.text.trim().isNotEmpty &&
                  body.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: Text(ar ? 'إرسال' : 'Send'),
          ),
        ],
      ),
    );
    final title = subject.text.trim(), message = body.text.trim();
    subject.dispose();
    body.dispose();
    if (accepted != true || !mounted) return;
    setState(() => _busy = true);
    final epoch = ++_epoch;
    try {
      final id = await ref
          .read(supportRepositoryProvider)
          .create(title, message);
      if (!mounted || epoch != _epoch) return;
      setState(() {
        _thread = id;
        _items = [];
        _title = title;
        _text.clear();
      });
      await _load();
    } catch (error) {
      if (mounted) setState(() => _clearDenied(error));
      if (mounted && epoch == _epoch) {
        setState(() {
          _busy = false;
          _error = ar
              ? 'تعذر الإرسال. حاول مجدداً.'
              : 'Could not send. Please retry.';
        });
      }
    }
  }

  Future<void> _send() async {
    final body = _text.text.trim();
    if (_busy || body.isEmpty || _thread == null) return;
    setState(() => _busy = true);
    final epoch = ++_epoch;
    try {
      await ref
          .read(supportRepositoryProvider)
          .send(_thread!, body, admin: widget.admin);
      if (!mounted || epoch != _epoch) return;
      _text.clear();
      await _load();
    } catch (error) {
      if (mounted) setState(() => _clearDenied(error));
      if (mounted && epoch == _epoch) {
        setState(() {
          _busy = false;
          _error = ar
              ? 'تعذر الإرسال. رسالتك محفوظة هنا للمحاولة.'
              : 'Could not send. Your draft is kept here.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (previous, next) {
      if (previous?.session?.user.id != next.session?.user.id) {
        _epoch++;
        setState(() {
          _items = [];
          _thread = null;
          _items = [];
          _text.clear();
          _error = null;
        });
      }
    });
    return Scaffold(
      appBar: AppBar(
        title: Text(_title ?? (ar ? 'خدمة العملاء' : 'Customer support')),
        leading: _thread == null
            ? null
            : BackButton(
                onPressed: () {
                  setState(() {
                    _thread = null;
                    _items = [];
                    _title = null;
                    _text.clear();
                  });
                  _load();
                },
              ),
        actions: [
          if (widget.admin && _thread != null)
            IconButton(
              tooltip: ar ? 'إغلاق المحادثة' : 'Close conversation',
              onPressed: _busy
                  ? null
                  : () async {
                      final accepted = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(
                            ar ? 'إغلاق المحادثة؟' : 'Close conversation?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(ar ? 'إلغاء' : 'Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(ar ? 'إغلاق' : 'Close'),
                            ),
                          ],
                        ),
                      );
                      if (accepted != true || !mounted) return;
                      setState(() => _busy = true);
                      final epoch = ++_epoch;
                      try {
                        await ref
                            .read(supportRepositoryProvider)
                            .close(_thread!);
                        if (!mounted || epoch != _epoch) return;
                        setState(() {
                          _thread = null;
                          _items = [];
                          _title = null;
                          _text.clear();
                        });
                        await _load();
                      } catch (error) {
                        if (mounted && epoch == _epoch) {
                          setState(() {
                            _clearDenied(error);
                            _busy = false;
                            _error = ar
                                ? 'تعذر إغلاق المحادثة'
                                : 'Could not close conversation';
                          });
                        }
                      }
                    },
              icon: const Icon(Icons.task_alt),
            ),
          IconButton(
            onPressed: _busy ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: _thread == null && !widget.admin
          ? FloatingActionButton.extended(
              onPressed: _busy ? null : _new,
              icon: const Icon(Icons.add_comment_outlined),
              label: Text(ar ? 'اسألنا' : 'Ask us'),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              children: [
                if (_busy) const LinearProgressIndicator(),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(_error!),
                  ),
                Expanded(
                  child: _items.isEmpty && !_busy
                      ? Center(
                          child: Text(
                            ar ? 'لا توجد محادثات بعد' : 'No conversations yet',
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          itemCount: _items.length,
                          itemBuilder: (context, i) {
                            final row = _items[i];
                            if (_thread == null) {
                              return Card(
                                child: ListTile(
                                  title: Text(row['subject'] as String),
                                  subtitle: Text(
                                    widget.admin
                                        ? '${(row['user'] as Map?)?['fullName'] ?? ''}'
                                        : '${row['updatedAt']}',
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    setState(() {
                                      _thread = row['id'] as String;
                                      _title = row['subject'] as String;
                                      _items = [];
                                    });
                                    _load();
                                  },
                                ),
                              );
                            }
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      row['fromAdmin'] == true
                                          ? (ar ? 'فريق FIXO' : 'FIXO support')
                                          : (ar ? 'الرسالة' : 'Message'),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelSmall,
                                    ),
                                    const SizedBox(height: 6),
                                    SelectableText(row['body'] as String),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                if (_thread != null)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _text,
                            maxLength: 2000,
                            minLines: 1,
                            maxLines: 4,
                            decoration: InputDecoration(
                              labelText: ar ? 'اكتب رسالتك' : 'Your message',
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _busy ? null : _send,
                          icon: const Icon(Icons.send_rounded),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
