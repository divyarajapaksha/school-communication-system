import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color primaryColor = Color(0xFF1A237E);
const Color backgroundColor = Color(0xFFFFF7FF);


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const SmartConnectApp());
}

class SmartConnectApp extends StatelessWidget {
  const SmartConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Connect',
      home: const SplashPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> loginUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter email and password')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final userEmail = credential.user?.email;

      if (userEmail == null) {
        showMessage('Login failed');
        return;
      }

      final result = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: userEmail)
          .get();

      if (result.docs.isEmpty) {
        showMessage('User role not found');
        return;
      }

      final role = result.docs.first['role'];

      if (!mounted) return;
      if (role == 'admin') {
      Navigator.pushReplacement(
      context,
     MaterialPageRoute(builder: (_) => const AdminPage()),
     );
     }
      if (role == 'teacher') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TeacherPage()),
        );
      } else if (role == 'parent') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ParentPage()),
        );
      } else {
        showMessage('Invalid role');
      }
    } on FirebaseAuthException catch (e) {
      showMessage(e.message ?? 'Login error');
    } catch (e) {
      showMessage('Error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// Logo
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: primaryColor,
                    child: const Icon(
                      Icons.school,
                      size: 45,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// Title
                  const Text(
                    'SMART CONNECT',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Login to continue',
                    style: TextStyle(color: Colors.black54),
                  ),

                  const SizedBox(height: 24),

                  /// Email
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// Password
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: isLoading ? null : loginUser,
                      child: isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              'Login',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  List<Map<String, dynamic>> allStudents = [];
  List<Map<String, dynamic>> students = [];
  Map<String, String> attendanceStatus = {};
  bool isLoading = true;
String? assignedClass;

  @override
void initState() {
  super.initState();
  fetchAssignedClass();
}
Future<void> fetchAssignedClass() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) return;

  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();

  if (!doc.exists) return;

  setState(() {
    assignedClass = doc['assignedClass'];
  });
}

  Future<void> fetchStudents() async {
    final snapshot = await FirebaseFirestore.instance
    .collection('students')
    .where('grade', isEqualTo: assignedClass)
    .get();

    final data = snapshot.docs.map((doc) {
      return {
        'id': doc.id,
        ...doc.data(),
      };
    }).toList();
  
    setState(() {
      allStudents = data;
      students = data;

      for (var student in data) {
        attendanceStatus[student['id']] = 'Present';
      }

      isLoading = false;
    });
  }

 Future<void> saveAttendance() async {
  final today = DateTime.now();
  final date =
      '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

  for (var student in students) {
    final studentId = student['id'];

    await FirebaseFirestore.instance
        .collection('attendance')
        .doc('${studentId}_$date') // ✅ unique per student per day
        .set({
      'studentId': studentId,
      'name': student['name'],
      'grade': student['grade'],
      'status': attendanceStatus[studentId] ?? 'Present',
      'date': date,
    });
  }

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Attendance saved')),
  );
}

  @override
  Widget build(BuildContext context) {
    
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final presentCount =
        attendanceStatus.values.where((s) => s == 'Present').length;
    final absentCount =
        attendanceStatus.values.where((s) => s == 'Absent').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Attendance - Grade 5',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Total Students: ${students.length}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Student List',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final student = students[index];
                  final studentId = student['id'];

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${index + 1}. ${student['name']}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          const Text('Present'),
                          Radio<String>(
                            value: 'Present',
                            groupValue: attendanceStatus[studentId],
                            onChanged: (value) {
                              setState(() {
                                attendanceStatus[studentId] = value!;
                              });
                            },
                          ),
                          const Text('Absent'),
                          Radio<String>(
                            value: 'Absent',
                            groupValue: attendanceStatus[studentId],
                            onChanged: (value) {
                              setState(() {
                                attendanceStatus[studentId] = value!;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: ElevatedButton(
                onPressed: saveAttendance,
                child: const Text('Save Attendance'),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                'Present: $presentCount   Absent: $absentCount',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class AttendanceHistoryPage extends StatefulWidget {
  const AttendanceHistoryPage({super.key});

  @override
  State<AttendanceHistoryPage> createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
  List<Map<String, dynamic>> records = [];
  bool isLoading = true;

  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    fetchAttendance();
  }

  String get formattedDate {
    return '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
  }

  Future<void> fetchAttendance() async {
    setState(() {
      isLoading = true;
    });

    final snapshot = await FirebaseFirestore.instance
        .collection('attendance')
        .where('date', isEqualTo: formattedDate)
        .get();

    final data = snapshot.docs.map((doc) {
      return {
        'id': doc.id,
        ...doc.data(),
      };
    }).toList();

    setState(() {
      records = data;
      isLoading = false;
    });
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
      fetchAttendance();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance History'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Date: $formattedDate',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: pickDate,
                  child: const Text('Choose Date'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (records.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('No attendance records found'),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final item = records[index];
                    final status = item['status'] ?? '';

                    return Card(
                      child: ListTile(
                        title: Text(item['name'] ?? 'No name'),
                        subtitle: Text('Grade: ${item['grade'] ?? ''}'),
                        trailing: Text(
                          status,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: status == 'Present'
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class TeacherPage extends StatelessWidget {
  const TeacherPage({super.key});

  Widget teacherButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 260,
      height: 50,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: Icon(icon),
        label: Text(text),
        onPressed: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Teacher Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 20),

              CircleAvatar(
                radius: 45,
                backgroundColor: primaryColor,
                child: const Icon(
                  Icons.school,
                  size: 45,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Welcome Teacher',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              teacherButton(
                icon: Icons.calendar_month,
                text: 'Open Attendance',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AttendancePage()),
                  );
                },
              ),

              const SizedBox(height: 14),

              teacherButton(
                icon: Icons.history,
                text: 'Attendance History',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AttendanceHistoryPage(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 14),

              teacherButton(
                icon: Icons.person_search,
                text: 'View Student Profiles',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TeacherStudentListPage(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 14),

              teacherButton(
                icon: Icons.message,
                text: 'Send Message',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TeacherSendMessagePage(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 14),

              teacherButton(
                icon: Icons.forum,
                text: 'View Messages',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TeacherMessagesPage(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 14),

              teacherButton(
                icon: Icons.campaign,
                text: 'Create Announcement',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TeacherAnnouncementPage(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 14),

              teacherButton(
              icon: Icons.menu_book,
              text: 'Add Homework',
              onTap: () {
              Navigator.push(
             context,
                MaterialPageRoute(builder: (_) => const TeacherHomeworkPage()),
                  );
                 },
              ),

              const SizedBox(height: 14),

              teacherButton(
                icon: Icons.bar_chart,
                text: 'Add Report',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TeacherAddReportPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class TeacherMessagesPage extends StatelessWidget {
  const TeacherMessagesPage({super.key});

  String getDateText(Map<String, dynamic> msg) {
    final timestamp = msg['timestamp'];

    if (timestamp is Timestamp) {
      return timestamp.toDate().toString().substring(0, 16);
    }

    return (timestamp ?? '').toString();
  }

  String getMessageText(Map<String, dynamic> msg) {
    return (msg['content'] ?? msg['message'] ?? 'No message').toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parent Messages'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('messages')
            .where('senderRole', isEqualTo: 'parent')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No parent replies found'));
          }

          final messages = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final msg =
                  messages[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.message),
                  title: Text(getMessageText(msg)),
                  subtitle: Text(
                    'Student: ${msg['studentId'] ?? ''}',
                  ),
                  trailing: Text(getDateText(msg)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
class TeacherSendMessagePage extends StatefulWidget {
  const TeacherSendMessagePage({super.key});

  @override
  State<TeacherSendMessagePage> createState() => _TeacherSendMessagePageState();
}

class _TeacherSendMessagePageState extends State<TeacherSendMessagePage> {
  final messageController = TextEditingController();

  List<Map<String, dynamic>> students = [];
  String? selectedStudentId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('students').get();

    final data = snapshot.docs.map((doc) {
      return {
        'id': doc.id,
        ...doc.data(),
      };
    }).toList();

    setState(() {
      students = data;
      isLoading = false;
    });
  }

  Future<void> sendMessage() async {
    if (selectedStudentId == null || messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select student and enter message')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('messages').add({
      'content': messageController.text.trim(),
      'studentId': selectedStudentId,
      'teacherName': 'Teacher Name',
      'timestamp': Timestamp.now(),
      'senderRole': 'teacher',
    });

    messageController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message sent')),
    );
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Message'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedStudentId,
                    decoration: const InputDecoration(
                      labelText: 'Select Student',
                      border: OutlineInputBorder(),
                    ),
                    items: students.map((student) {
                      return DropdownMenuItem<String>(
                        value: student['id'],
                        child: Text(student['name'] ?? 'No name'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedStudentId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: messageController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: sendMessage,
                      child: const Text('Send Message'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
class ParentPage extends StatelessWidget {
  const ParentPage({super.key});

 Future<Map<String, dynamic>?> fetchChildData() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;

  
  DocumentSnapshot<Map<String, dynamic>> parentDoc =
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

  Map<String, dynamic>? parentData;

  if (parentDoc.exists) {
    parentData = parentDoc.data();
  } else {
    // 2. Fallback: find parent by email
    final email = user.email;

    if (email == null) return null;

    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    parentData = query.docs.first.data();
  }

  final childId = parentData?['childId']?.toString().trim();

  if (childId == null || childId.isEmpty) return null;

  final childDoc = await FirebaseFirestore.instance
      .collection('students')
      .doc(childId)
      .get();

  if (!childDoc.exists) return null;

  return {
    'childId': childId,
    ...childDoc.data()!,
  };
}

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: fetchChildData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Scaffold(
            body: Center(child: Text('Child data not found')),
          );
        }

        final child = snapshot.data!;
        final childId = child['childId'];

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            title: const Text('SMART CONNECT'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'My Child',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Card(
                   color: Colors.white,
                   shape: RoundedRectangleBorder(
                   borderRadius: BorderRadius.circular(16),
                     ),
                   elevation: 4,
                   child: ListTile(
                   leading: CircleAvatar(
                   backgroundColor: primaryColor,
                   child: const Icon(Icons.person, color: Colors.white),
                   ),
                   title: Text(
                   child['name'] ?? 'No name',
                   style: const TextStyle(fontWeight: FontWeight.bold),
                   ),
                   subtitle: Text('Grade: ${child['grade'] ?? ''}'),
                  ),
                  ),
                    
                  const SizedBox(height: 20),
                  const Text(
                    'Dashboard',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      dashboardButton(
                        context,
                        icon: Icons.calendar_month,
                        title: 'Attendance',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ParentAttendanceRecordPage(childId: childId),
                            ),
                          );
                        },
                      ),
                      dashboardButton(
                        context,
                         icon: Icons.message,
                          title: 'Messages',
                           onTap: () {
                           Navigator.push(
                            context,
                              MaterialPageRoute(
                               builder: (_) => ParentMessagesPage(childId: childId),
                                  ),
                                   );
                                    },
                                      ),
                        dashboardButton(
                         context,
                           icon: Icons.person,
                              title: 'Student Profile',
                               onTap: () {
                            Navigator.push(
                             context,
                               MaterialPageRoute(
                                builder: (_) => StudentProfilePage(child: child),
                                    ),
                                      );
                                        },
                                          ),
                                      
                      dashboardButton(
                      context,
                      icon: Icons.home_work,
                      title: 'Homework',
                      onTap: () {
                      Navigator.push(
                      context,
                      MaterialPageRoute(
                     builder: (_) => ParentHomeworkPage(childGrade: child['grade'] ?? ''),
                          ),
                            );
                              },
                                ),
                      dashboardButton(
                         context,
                         icon: Icons.announcement,
                         title: 'Announcements',
                         onTap: () {
                       Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ParentAnnouncementsPage()),
                         );
                           },
                              ),
                      dashboardButton(
                         context,
                         icon: Icons.bar_chart,
                         title: 'Reports',
                        onTap: () {
                      Navigator.push(
                      context,
                        MaterialPageRoute(
                       builder: (_) => ParentReportsPage(childId: childId),
                         ),
                       );
                     },
                    ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget dashboardButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.indigo.shade900,
        foregroundColor: Colors.white,
        elevation: 6, 
        shadowColor: Colors.black45,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      onPressed: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32),
          const SizedBox(height: 8),
          Text(
          title,
         textAlign: TextAlign.center,
         style: const TextStyle(fontWeight: FontWeight.w600),
         ),
        ],
      ),
    );
  }
}
 
 
class ParentAttendanceRecordPage extends StatefulWidget {
  final String childId;

  const ParentAttendanceRecordPage({
    super.key,
    required this.childId,
  });

  @override
  State<ParentAttendanceRecordPage> createState() =>
      _ParentAttendanceRecordPageState();
}

class _ParentAttendanceRecordPageState
    extends State<ParentAttendanceRecordPage> {
  List<Map<String, dynamic>> records = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAttendanceRecords();
  }

  Future<void> fetchAttendanceRecords() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('attendance')
        .where('studentId', isEqualTo: widget.childId)
        .get();

    final data = snapshot.docs.map((doc) {
      return {
        'id': doc.id,
        ...doc.data(),
      };
    }).toList();

    setState(() {
      records = data;
      isLoading = false;
    });
  }

  double calculateAttendancePercentage() {
    if (records.isEmpty) return 0;

    final presentCount =
        records.where((record) => record['status'] == 'Present').length;

    return (presentCount / records.length) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final percentage = calculateAttendancePercentage();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Record'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : records.isEmpty
              ? const Center(child: Text('No attendance records found'))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.percent),
                          title: const Text('Attendance Percentage'),
                          subtitle: Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: records.length,
                          itemBuilder: (context, index) {
                            final item = records[index];
                            final status = item['status'] ?? '';

                            return Card(
                              child: ListTile(
                                leading: Icon(
                                  status == 'Present'
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: status == 'Present'
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                title: Text(item['date'] ?? 'No date'),
                                subtitle: Text(item['name'] ?? ''),
                                trailing: Text(
                                  status,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: status == 'Present'
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
class ParentMessagesPage extends StatefulWidget {
  final String childId;

  const ParentMessagesPage({
    super.key,
    required this.childId,
  });

  @override
  State<ParentMessagesPage> createState() => _ParentMessagesPageState();
}

class _ParentMessagesPageState extends State<ParentMessagesPage> {
  final replyController = TextEditingController();

  String getDateText(dynamic msg) {
    final timestamp = msg['timestamp'];

    if (timestamp is Timestamp) {
      return timestamp.toDate().toString().substring(0, 16);
    }

    return (msg['date'] ?? timestamp ?? '').toString();
  }

  String getMessageText(dynamic msg) {
    return (msg['content'] ?? msg['message'] ?? 'No message').toString();
  }

  Future<void> sendParentReply() async {
    if (replyController.text.trim().isEmpty) return;

    await FirebaseFirestore.instance.collection('messages').add({
      'content': replyController.text.trim(),
      'studentId': widget.childId,
      'teacherName': 'Parent',
      'senderRole': 'parent',
      'isRead': false,
      'timestamp': Timestamp.now(),
    });

    replyController.clear();
  }

  Future<void> markTeacherMessagesAsRead(List<QueryDocumentSnapshot> docs) async {
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      if (data['senderRole'] == 'teacher' && data['isRead'] == false) {
        await FirebaseFirestore.instance
            .collection('messages')
            .doc(doc.id)
            .update({'isRead': true});
      }
    }
  }

  @override
  void dispose() {
    replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .where('studentId', isEqualTo: widget.childId)            
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No messages found'));
                }

                final messages = snapshot.data!.docs;

                markTeacherMessagesAsRead(messages);

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg =
                        messages[index].data() as Map<String, dynamic>;

                    final isParent = msg['senderRole'] == 'parent';

                    return Align(
                      alignment: isParent
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isParent
                              ? Colors.indigo.shade900
                              : Colors.indigo.shade100,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: isParent
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Text(
                              isParent
                                  ? 'You'
                                  : (msg['teacherName'] ?? 'Teacher')
                                      .toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isParent
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              getMessageText(msg),
                              style: TextStyle(
                                fontSize: 16,
                                color: isParent
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  getDateText(msg),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isParent
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                ),
                                if (isParent) ...[
                                  const SizedBox(width: 6),
                                  Icon(
                                    msg['isRead'] == true
                                        ? Icons.done_all
                                        : Icons.check,
                                    size: 14,
                                    color: Colors.white70,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: replyController,
                    decoration: const InputDecoration(
                      hintText: 'Type reply...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendParentReply,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class TeacherAnnouncementPage extends StatefulWidget {
  const TeacherAnnouncementPage({super.key});

  @override
  State<TeacherAnnouncementPage> createState() =>
      _TeacherAnnouncementPageState();
}

class _TeacherAnnouncementPageState extends State<TeacherAnnouncementPage> {
  final titleController = TextEditingController();
  final messageController = TextEditingController();

  Future<void> saveAnnouncement() async {
    if (titleController.text.trim().isEmpty ||
        messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter title and message')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('announcements').add({
      'title': titleController.text.trim(),
      'message': messageController.text.trim(),
      'timestamp': Timestamp.now(),
    });

    titleController.clear();
    messageController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Announcement created')),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Announcement'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Announcement Title',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: messageController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Announcement Message',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saveAnnouncement,
                child: const Text('Post Announcement'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ParentAnnouncementsPage extends StatelessWidget {
  const ParentAnnouncementsPage({super.key});

  String getDateText(Map<String, dynamic> item) {
    final timestamp = item['timestamp'];

    if (timestamp is Timestamp) {
      return timestamp.toDate().toString().substring(0, 16);
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('announcements')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No announcements found'));
          }

          final announcements = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              final item =
                  announcements[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.announcement),
                  title: Text(
                    (item['title'] ?? 'No title').toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text((item['message'] ?? '').toString()),
                  trailing: Text(getDateText(item)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
class StudentProfilePage extends StatelessWidget {
  final Map<String, dynamic> child;

  const StudentProfilePage({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.indigo.shade100,
                      child: Icon(
                        Icons.person,
                        size: 55,
                        color: Colors.indigo.shade900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      child['name'] ?? 'No name',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      child['grade'] ?? 'No grade',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            profileCard(
              icon: Icons.badge,
              title: 'Student ID',
              value: child['studentId'] ?? '',
            ),
            profileCard(
              icon: Icons.cake,
              title: 'Birthday',
              value: child['birthday'] ?? '',
            ),
            profileCard(
              icon: Icons.home,
              title: 'Address',
              value: child['address'] ?? '',
            ),
            profileCard(
              icon: Icons.phone,
              title: 'Phone',
              value: child['phone'] ?? '',
            ),
            profileCard(
              icon: Icons.health_and_safety,
              title: 'Illness',
              value: child['illness'] ?? '',
            ),
            profileCard(
              icon: Icons.school,
              title: 'Grade',
              value: child['grade'] ?? '',
            ),
          ],
        ),
      ),
    );
  }

  Widget profileCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.indigo.shade50,
          child: Icon(icon, color: Colors.indigo.shade900),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          value.isEmpty ? 'Not available' : value,
          style: const TextStyle(fontSize: 15),
        ),
      ),
    );
  }
}
class TeacherStudentListPage extends StatelessWidget {
  const TeacherStudentListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('students')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final students = snapshot.data!.docs;

          return ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student =
                  students[index].data() as Map<String, dynamic>;

              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(student['name'] ?? ''),
                subtitle: Text(student['grade'] ?? ''),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          StudentProfilePage(child: student),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
class TeacherAddReportPage extends StatefulWidget {
  const TeacherAddReportPage({super.key});

  @override
  State<TeacherAddReportPage> createState() => _TeacherAddReportPageState();
}

class _TeacherAddReportPageState extends State<TeacherAddReportPage> {
  final examController = TextEditingController();
  final subjectController = TextEditingController();
  final marksController = TextEditingController();
  final gradeController = TextEditingController();
  final commentController = TextEditingController();

  List<Map<String, dynamic>> students = [];
  String? selectedStudentDocId;
  bool isLoadingStudents = true;

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('students').get();

    final data = snapshot.docs.map((doc) {
      final student = doc.data();

      return {
        'docId': doc.id,
        'studentId': student['studentId'] ?? doc.id,
      };
    }).toList();

    setState(() {
      students = data;
      isLoadingStudents = false;
    });
  }

  Future<void> saveReport() async {
    if (selectedStudentDocId == null ||
        examController.text.trim().isEmpty ||
        subjectController.text.trim().isEmpty ||
        marksController.text.trim().isEmpty ||
        gradeController.text.trim().isEmpty ||
        commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill all fields')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('reports').add({
      'studentId': selectedStudentDocId,
      'examName': examController.text.trim(),
      'subject': subjectController.text.trim(),
      'marks': int.tryParse(marksController.text.trim()) ?? 0,
      'grade': gradeController.text.trim(),
      'teacherComment': commentController.text.trim(),
      'timestamp': Timestamp.now(),
    });

    examController.clear();
    subjectController.clear();
    marksController.clear();
    gradeController.clear();
    commentController.clear();

    setState(() {
      selectedStudentDocId = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report saved')),
    );
  }

  @override
  void dispose() {
    examController.dispose();
    subjectController.dispose();
    marksController.dispose();
    gradeController.dispose();
    commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Add Report'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            isLoadingStudents
                ? const CircularProgressIndicator()
                : DropdownButtonFormField<String>(
                    value: selectedStudentDocId,
                    decoration: const InputDecoration(
                      labelText: 'Select Student ID',
                      border: OutlineInputBorder(),
                    ),
                    items: students.map((student) {
                      return DropdownMenuItem<String>(
                        value: student['docId'],
                        child: Text(student['studentId'].toString()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedStudentDocId = value;
                      });
                    },
                  ),

            const SizedBox(height: 16),

            TextField(
              controller: examController,
              decoration: const InputDecoration(
                labelText: 'Exam Name',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: subjectController,
              decoration: const InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: marksController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Marks',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: gradeController,
              decoration: const InputDecoration(
                labelText: 'Grade',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Comment',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: saveReport,
                child: const Text('Save Report'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class ParentReportsPage extends StatelessWidget {
  final String childId;

  const ParentReportsPage({super.key, required this.childId});
  String insight(int marks) {
  if (marks >= 75) return "Good Performance";
  if (marks >= 50) return "Average";
  return "Needs Improvement";
}
Color insightColor(int marks) {
  if (marks >= 75) return Colors.green;
  if (marks >= 50) return Colors.orange;
  return Colors.red;
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .where('studentId', isEqualTo: childId)
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final reports = snapshot.data!.docs;

          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final r = reports[index].data() as Map<String, dynamic>;
              final marks = int.tryParse(r['marks'].toString()) ?? 0;

              return Card(
                child: ListTile(
                  title: Text('${r['subject']} - ${r['marks']}'),
                  subtitle: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Text('${r['examName']}'),
                    Text('Comment: ${r['teacherComment']}'),
                    Text( 'Insight: ${insight(marks)}',
                     style: TextStyle(
                     fontWeight: FontWeight.bold,
                     color: insightColor(marks),
                       ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  Widget adminCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 90,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        onPressed: onTap,
        child: Row(
          children: [
            Icon(icon, size: 34),
            const SizedBox(width: 18),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
  IconButton(
    icon: const Icon(Icons.logout),
    onPressed: () async {
      await FirebaseAuth.instance.signOut();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    },
  ),
],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            Center(
              child: CircleAvatar(
                radius: 45,
                backgroundColor: primaryColor,
                child: const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                  size: 45,
                ),
              ),
            ),

            const SizedBox(height: 16),

            const Center(
              child: Text(
                'Welcome Admin',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 30),

            adminCard(
              icon: Icons.school,
              title: 'Manage Students',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminStudentsPage()),
                );
              },
            ),

            const SizedBox(height: 16),

            adminCard(
              icon: Icons.person,
              title: 'Manage Teachers',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminTeachersPage()),
                );
              },
            ),
            

            const SizedBox(height: 16),

            adminCard(
              icon: Icons.class_,
              title: 'Assign Class',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AssignClassPage()),
                );
              },
            ),

            const SizedBox(height: 16),

            adminCard(
            icon: Icons.book,
            title: 'Assign Subject',
            onTap: () {
            Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AssignSubjectPage()),
              );
            },
           ),
          ],
        ),
      ),
    );
  }
}
class AdminStudentsPage extends StatelessWidget {
  const AdminStudentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Students')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('students').snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final students = snapshot.data!.docs;

          return ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, index) {
              final s = students[index].data() as Map<String, dynamic>;

              return Card(
                child: ListTile(
                  title: Text(s['name'] ?? ''),
                  subtitle: Text(s['grade'] ?? ''),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
class AdminTeachersPage extends StatelessWidget {
  const AdminTeachersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teachers')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'teacher')
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final teachers = snapshot.data!.docs;

          return ListView.builder(
            itemCount: teachers.length,
            itemBuilder: (context, index) {
              final t = teachers[index].data() as Map<String, dynamic>;

              return Card(
                child: ListTile(
                  title: Text(t['email'] ?? ''),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
class AssignClassPage extends StatefulWidget {
  const AssignClassPage({super.key});

  @override
  State<AssignClassPage> createState() => _AssignClassPageState();
}

class _AssignClassPageState extends State<AssignClassPage> {
  String? selectedTeacherId;
  String? selectedClass;

  List<QueryDocumentSnapshot> teachers = [];

  final List<String> classes = [
    'Grade 1',
    'Grade 2',
    'Grade 3',
    'Grade 4',
    'Grade 5',
  ];

  @override
  void initState() {
    super.initState();
    fetchTeachers();
  }

  Future<void> fetchTeachers() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'teacher')
        .get();

    setState(() {
      teachers = snapshot.docs;
    });
  }

  Future<void> assignClass() async {
    if (selectedTeacherId == null || selectedClass == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(selectedTeacherId)
        .update({
      'assignedClass': selectedClass,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Class assigned successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assign Class to Teacher')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            /// Teacher dropdown
            DropdownButtonFormField<String>(
              hint: const Text('Select Teacher'),
              value: selectedTeacherId,
              items: teachers.map((t) {
                final data = t.data() as Map<String, dynamic>;

                return DropdownMenuItem(
                  value: t.id,
                  child: Text(data['email'] ?? 'No email'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedTeacherId = value;
                });
              },
            ),

            const SizedBox(height: 20),

            /// Class dropdown
            DropdownButtonFormField<String>(
              hint: const Text('Select Class'),
              value: selectedClass,
              items: classes.map((c) {
                return DropdownMenuItem(
                  value: c,
                  child: Text(c),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedClass = value;
                });
              },
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: assignClass,
              child: const Text('Assign Class'),
            ),
          ],
        ),
      ),
    );
  }
}
class AssignSubjectPage extends StatefulWidget {
  const AssignSubjectPage({super.key});

  @override
  State<AssignSubjectPage> createState() => _AssignSubjectPageState();
}

class _AssignSubjectPageState extends State<AssignSubjectPage> {
  String? selectedTeacherId;
  String? selectedSubject;

  List<QueryDocumentSnapshot> teachers = [];
  List<QueryDocumentSnapshot> subjects = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final teacherSnap = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'teacher')
        .get();

    final subjectSnap =
        await FirebaseFirestore.instance.collection('subjects').get();

    setState(() {
      teachers = teacherSnap.docs;
      subjects = subjectSnap.docs;
    });
  }

  Future<void> assignSubject() async {
    if (selectedTeacherId == null || selectedSubject == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(selectedTeacherId)
        .update({
      'subject': selectedSubject,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Subject assigned')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assign Subject')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            /// Teacher dropdown
            DropdownButtonFormField<String>(
              hint: const Text('Select Teacher'),
              items: teachers.map((t) {
                final data = t.data() as Map<String, dynamic>;
                return DropdownMenuItem(
                  value: t.id,
                  child: Text(data['email'] ?? ''),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedTeacherId = value;
                });
              },
            ),

            const SizedBox(height: 20),

            
            DropdownButtonFormField<String>(
            hint: const Text('Select Subject'),
            value: selectedSubject,
            items: subjects.map((s) {
          final data = s.data() as Map<String, dynamic>;
           final subjectName = data['name'].toString();

           return DropdownMenuItem<String>(
           value: subjectName,
           child: Text(subjectName),
           );
          }).toList(),
          onChanged: (value) {
          setState(() {
          selectedSubject = value;
          });
          },
          ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: assignSubject,
              child: const Text('Assign Subject'),
            ),
          ],
        ),
      ),
    );
  }
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Image.asset(
            'assets/images/children.jpg',
            width: double.infinity,
            height: 220,
            fit: BoxFit.cover,
          ),
          const SizedBox(height: 40),
          Image.asset(
            'assets/images/logo.jpeg',
            height: 180,
          ),
          const SizedBox(height: 30),
          const Text(
            'School Communication\n& Safety',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 50),
          const CircularProgressIndicator(
            color: primaryColor,
          ),
        ],
      ),
    );
  }
}
class TeacherHomeworkPage extends StatefulWidget {
  const TeacherHomeworkPage({super.key});

  @override
  State<TeacherHomeworkPage> createState() => _TeacherHomeworkPageState();
}

class _TeacherHomeworkPageState extends State<TeacherHomeworkPage> {
  final classController = TextEditingController();
  final subjectController = TextEditingController();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final dueDateController = TextEditingController();

  Future<void> saveHomework() async {
    if (classController.text.trim().isEmpty ||
        subjectController.text.trim().isEmpty ||
        titleController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty ||
        dueDateController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill all fields')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('homework').add({
      'className': classController.text.trim(),
      'subject': subjectController.text.trim(),
      'title': titleController.text.trim(),
      'description': descriptionController.text.trim(),
      'dueDate': dueDateController.text.trim(),
      'timestamp': Timestamp.now(),
    });

    classController.clear();
    subjectController.clear();
    titleController.clear();
    descriptionController.clear();
    dueDateController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Homework added')),
    );
  }

  @override
  void dispose() {
    classController.dispose();
    subjectController.dispose();
    titleController.dispose();
    descriptionController.dispose();
    dueDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Add Homework'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: classController,
              decoration: const InputDecoration(
                labelText: 'Class / Grade',
                hintText: 'Grade 5',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: subjectController,
              decoration: const InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Homework Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: dueDateController,
              decoration: const InputDecoration(
                labelText: 'Due Date',
                hintText: '2026-05-10',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: saveHomework,
                child: const Text('Save Homework'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ParentHomeworkPage extends StatelessWidget {
  final String childGrade;

  const ParentHomeworkPage({
    super.key,
    required this.childGrade,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Homework'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('homework')
            .where('className', isEqualTo: childGrade)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final homework = snapshot.data!.docs;

          if (homework.isEmpty) {
            return const Center(child: Text('No homework found'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: homework.length,
            itemBuilder: (context, index) {
              final hw = homework[index].data() as Map<String, dynamic>;

              return Card(
                color: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: const Icon(Icons.menu_book),
                  title: Text(hw['title'] ?? ''),
                  subtitle: Text(
                    '${hw['subject'] ?? ''}\n${hw['description'] ?? ''}\nDue: ${hw['dueDate'] ?? ''}',
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}