import 'package:flutter/material.dart';

void main() => runApp(CodePreviewApp());

class CodePreviewApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CodePreviewScreen(),
    );
  }
}

class CodePreviewScreen extends StatefulWidget {
  @override
  _CodePreviewScreenState createState() => _CodePreviewScreenState();
}

class _CodePreviewScreenState extends State<CodePreviewScreen> {
  final ScrollController mainScrollController = ScrollController();
  final ScrollController miniScrollController = ScrollController();
  final GlobalKey miniViewKey = GlobalKey();

  bool isScrollingMini = false;
  bool isScrollingMain = false;

  double? highlightedPositionY; // Позиция для подсветки

  @override
  void initState() {
    super.initState();

    // Прокрутка основной области влияет на мини-область
    mainScrollController.addListener(() {
      if (!isScrollingMini) {
        isScrollingMain = true;
        miniScrollController.jumpTo(mainScrollController.offset / 5);
        isScrollingMain = false;
      }
    });

    // Прокрутка мини-области влияет на основную
    miniScrollController.addListener(() {
      if (!isScrollingMain) {
        isScrollingMini = true;
        mainScrollController.jumpTo(miniScrollController.offset * 5);
        isScrollingMini = false;
      }
    });
  }

  void _onMiniVersionTap(TapDownDetails details) {
    // Найти высоту мини-версии
    final RenderBox renderBox = miniViewKey.currentContext!.findRenderObject() as RenderBox;
    final double miniHeight = renderBox.size.height;

    // Найти позицию, на которую нажали
    final double tapPositionY = details.localPosition.dy;

    // Пропорционально перевести эту позицию в основную область
    final double targetMainOffset = (tapPositionY / miniHeight) * mainScrollController.position.maxScrollExtent;

    // Переместить основную область
    mainScrollController.jumpTo(targetMainOffset);

    // Сохранить позицию для подсветки
    setState(() {
      highlightedPositionY = tapPositionY;
    });

    // Убрать подсветку через 1 секунду
    Future.delayed(Duration(milliseconds:800), () {
      setState(() {
        highlightedPositionY = null; // Скрыть подсветку
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Code Preview with Highlight'),
      ),
      body: Row(
        children: [
          // Основная область
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              controller: mainScrollController,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: SelectableText(
                  _exampleCode,
                  style: TextStyle(fontSize: 16, fontFamily: 'monospace'),
                ),
              ),
            ),
          ),
          // Разделительная линия
          Container(
            width: 2,
            color: Colors.grey[300],
          ),
          // Миниатюрная область с GestureDetector и CustomPaint
          Expanded(
            flex: 1,
            child: GestureDetector(
              key: miniViewKey,
              onTapDown: _onMiniVersionTap,
              child: Stack(
                children: [
                  SingleChildScrollView(
                    controller: miniScrollController,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Text(
                        _exampleCode,
                        style: TextStyle(fontSize: 8, fontFamily: 'monospace'),
                      ),
                    ),
                  ),
                  // CustomPaint для подсветки
                  if (highlightedPositionY != null)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: HighlightPainter(highlightedPositionY!),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    mainScrollController.dispose();
    miniScrollController.dispose();
    super.dispose();
  }
}

// Painter для рисования подсветки
class HighlightPainter extends CustomPainter {
  final double positionY;

  HighlightPainter(this.positionY);

  @override
  void paint(Canvas canvas, Size size) {
    // Высота прямоугольника подсветки
    final double highlightHeight = 50.0;

    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    // Нарисовать прямоугольник
    canvas.drawRect(
      Rect.fromLTWH(0, positionY - highlightHeight / 2, size.width, highlightHeight),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Перерисовывать, когда изменяется highlightedPositionY
  }
}

// Пример кода для отображения
const String _exampleCode = '''
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text("Example Code"),
        ),
        body: Center(
          child: Text("Hello, Flutter!"),
        ),
      ),
    );
  }
}

// Another example text to simulate a long code file...
// Scroll through to see how the synchronization works.
class AnotherClass {
  void exampleMethod() {
    print("This is a test method.");
  }
}

''';
