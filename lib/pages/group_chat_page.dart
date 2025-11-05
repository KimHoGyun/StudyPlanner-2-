import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/chat_service.dart';
import '../models/chat_models.dart';

class GroupChatPage extends StatefulWidget {
  final Map<String, dynamic> studyGroup;
  final String token;
  final int userId;

  const GroupChatPage({
    Key? key,
    required this.studyGroup,
    required this.token,
    required this.userId,
  }) : super(key: key);

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();

  List<ChatMessage> messages = [];
  bool isLoading = false;
  bool isSending = false;
  Timer? _pollTimer;
  DateTime? _lastMessageTime;

  late TabController _tabController;


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMessages();
    _startPolling();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_lastMessageTime != null) {
        _pollNewMessages();
      }
    });
  }

  Future<void> _loadMessages() async {
    setState(() {
      isLoading = true;
    });

    try {
      final loadedMessages = await ChatService.getMessages(widget.studyGroup['id']);
      setState(() {
        messages = loadedMessages;
        if (messages.isNotEmpty) {
          _lastMessageTime = messages.first.createdAt;
        }
        isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading messages: $e');
    }
  }

  Future<void> _pollNewMessages() async {
    if (_lastMessageTime == null) return;

    try {
      final newMessages = await ChatService.pollNewMessages(
        widget.studyGroup['id'],
        _lastMessageTime!,
      );

      if (newMessages.isNotEmpty) {
        setState(() {
          messages.insertAll(0, newMessages);
          _lastMessageTime = newMessages.first.createdAt;
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('Error polling messages: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || isSending) return;

    final content = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      isSending = true;
    });

    try {
      final result = await ChatService.sendMessage(
        studyGroupId: widget.studyGroup['id'],
        userId: widget.userId,
        content: content,
        messageType: 'text',
      );

      if (result['success'] == true) {
        await _loadMessages(); // 새로고침하여 최신 메시지 반영
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? '메시지 전송 실패')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류: $e')),
      );
    } finally {
      setState(() {
        isSending = false;
      });
    }
  }

  Future<void> _sendImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() {
        isSending = true;
      });

      final file = File(image.path);
      final uploadResult = await ChatService.uploadFile(
        file: file,
        studyGroupId: widget.studyGroup['id'],
        userId: widget.userId,
      );

      if (uploadResult['success'] == true) {
        await ChatService.sendMessage(
          studyGroupId: widget.studyGroup['id'],
          userId: widget.userId,
          content: '이미지를 보냈습니다.',
          messageType: 'image',
          fileName: uploadResult['fileName'],
          fileUrl: uploadResult['fileUrl'],
        );
        await _loadMessages();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(uploadResult['message'] ?? '이미지 전송 실패')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류: $e')),
      );
    } finally {
      setState(() {
        isSending = false;
      });
    }
  }

  Future<void> _sendFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx', 'txt'],
      );

      if (result == null) return;

      setState(() {
        isSending = true;
      });

      final file = File(result.files.single.path!);
      final uploadResult = await ChatService.uploadFile(
        file: file,
        studyGroupId: widget.studyGroup['id'],
        userId: widget.userId,
      );

      if (uploadResult['success'] == true) {
        await ChatService.sendMessage(
          studyGroupId: widget.studyGroup['id'],
          userId: widget.userId,
          content: '파일을 보냈습니다: ${result.files.single.name}',
          messageType: 'file',
          fileName: uploadResult['fileName'],
          fileUrl: uploadResult['fileUrl'],
        );
        await _loadMessages();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(uploadResult['message'] ?? '파일 전송 실패')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류: $e')),
      );
    } finally {
      setState(() {
        isSending = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.studyGroup['name'] ?? ''),
            Text(
              '멤버 ${widget.studyGroup['memberCount'] ?? 0}명',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.chat), text: '채팅'),
            Tab(icon: Icon(Icons.folder), text: '파일'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChatTab(),
          _buildFilesTab(),
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    return Column(
      children: [
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : messages.isEmpty
              ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  '첫 메시지를 보내보세요!',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          )
              : ListView.builder(
            controller: _scrollController,
            reverse: true,
            padding: const EdgeInsets.all(8),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              final isMyMessage = message.sender.id == widget.userId;
              return _buildMessageBubble(message, isMyMessage);
            },
          ),
        ),
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMyMessage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMyMessage) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                message.sender.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMyMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMyMessage)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 4),
                    child: Text(
                      message.sender.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    color: isMyMessage ? Theme.of(context).primaryColor : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: _buildMessageContent(message, isMyMessage),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
                  child: Text(
                    _formatTime(message.createdAt),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          if (isMyMessage) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade400,
              child: const Icon(Icons.person, size: 16, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageContent(ChatMessage message, bool isMyMessage) {
    final textColor = isMyMessage ? Colors.white : Colors.black87;

    if (message.isImage && message.fileUrl != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              message.fileUrl!,
              width: 200,
              height: 150,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 200,
                  height: 150,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.broken_image),
                );
              },
            ),
          ),
          if (message.content.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(message.content, style: TextStyle(color: textColor)),
          ],
        ],
      );
    }

    if (message.isFile && message.fileUrl != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getFileIcon(message.fileName ?? ''),
                  color: textColor,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.fileName ?? 'Unknown File',
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '파일 다운로드',
                        style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (message.content.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(message.content, style: TextStyle(color: textColor)),
          ],
        ],
      );
    }

    return Text(
      message.content,
      style: TextStyle(color: textColor),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: isSending ? null : () => _showAttachmentOptions(context),
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: '메시지를 입력하세요...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              maxLines: null,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          isSending
              ? const SizedBox(
            width: 40,
            height: 40,
            child: Center(child: CircularProgressIndicator()),
          )
              : IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
            color: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildFilesTab() {
    return FilesTabWidget(
      studyGroupId: widget.studyGroup['id'],
      userId: widget.userId,
    );
  }

  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo, color: Colors.blue),
              title: const Text('사진'),
              onTap: () {
                Navigator.pop(context);
                _sendImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file, color: Colors.green),
              title: const Text('파일'),
              onTap: () {
                Navigator.pop(context);
                _sendFile();
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${dateTime.month}/${dateTime.day}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }
}

class FilesTabWidget extends StatefulWidget {
  final int studyGroupId;
  final int userId;

  const FilesTabWidget({
    Key? key,
    required this.studyGroupId,
    required this.userId,
  }) : super(key: key);

  @override
  State<FilesTabWidget> createState() => _FilesTabWidgetState();
}

class _FilesTabWidgetState extends State<FilesTabWidget> {
  List<FileAttachment> files = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() {
      isLoading = true;
    });

    try {
      final loadedFiles = await ChatService.getFiles(widget.studyGroupId);
      setState(() {
        files = loadedFiles;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading files: $e');
    }
  }

  Future<void> _uploadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null) return;

      setState(() {
        isLoading = true;
      });

      final file = File(result.files.single.path!);
      final uploadResult = await ChatService.uploadFile(
        file: file,
        studyGroupId: widget.studyGroupId,
        userId: widget.userId,
      );

      if (uploadResult['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('파일 업로드 완료!')),
        );
        await _loadFiles(); // 파일 목록 새로고침
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(uploadResult['message'] ?? '파일 업로드 실패')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _downloadFile(FileAttachment file) async {
    try {
      if (await canLaunchUrl(Uri.parse(file.fileUrl))) {
        await launchUrl(Uri.parse(file.fileUrl));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('파일을 열 수 없습니다')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('다운로드 오류: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 파일 업로드 버튼
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : _uploadFile,
            icon: const Icon(Icons.cloud_upload),
            label: const Text('파일 업로드'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),

        // 파일 목록
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : files.isEmpty
              ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  '업로드된 파일이 없습니다',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  '첫 번째 파일을 업로드해보세요!',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          )
              : RefreshIndicator(
            onRefresh: _loadFiles,
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: files.length,
              itemBuilder: (context, index) {
                final file = files[index];
                return _buildFileCard(file);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFileCard(FileAttachment file) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getFileColor(file.fileName),
          child: Icon(
            _getFileIcon(file.fileName),
            color: Colors.white,
          ),
        ),
        title: Text(
          file.fileName,
          style: const TextStyle(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('업로드: ${file.uploader.name}'),
            Text('크기: ${file.fileSizeFormatted}'),
            Text('날짜: ${_formatDate(file.uploadedAt)}'),
          ],
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (file.isImage)
              IconButton(
                icon: const Icon(Icons.visibility),
                onPressed: () => _showImagePreview(file),
              ),
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => _downloadFile(file),
            ),
          ],
        ),
        onTap: () => _downloadFile(file),
      ),
    );
  }

  void _showImagePreview(FileAttachment file) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(file.fileName),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Flexible(
              child: Image.network(
                file.fileUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey.shade300,
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 64),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () => _downloadFile(file),
                icon: const Icon(Icons.download),
                label: const Text('다운로드'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
        return Icons.audio_file;
      case 'zip':
      case 'rar':
        return Icons.archive;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Colors.purple;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Colors.indigo;
      case 'mp3':
      case 'wav':
        return Colors.teal;
      case 'zip':
      case 'rar':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}