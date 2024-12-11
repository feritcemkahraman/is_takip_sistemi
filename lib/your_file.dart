// Klavye görünürlüğünü kontrol etmek için:
bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

// Klavye yüksekliğini almak için:
double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

// Klavye açıldığında/kapandığında bir şey yapmak için:
Widget build(BuildContext context) {
  return KeyboardListener(
    onKeyEvent: (event) {
      if (event is KeyDownEvent) {
        // Klavye açıldığında
      } else if (event is KeyUpEvent) {
        // Klavye kapandığında
      }
    },
    child: YourWidget(),
  );
} 