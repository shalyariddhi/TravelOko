import 'dart:io';

void fixErrors(String path) {
  final file = File(path);
  if (!file.existsSync()) return;

  String content = file.readAsStringSync();

  // Fix: The class 'Theme' doesn't have a constant constructor 'of'
  content = content.replaceAll('const [Theme.of(context)', '[Theme.of(context)');
  
  // Fix: Methods can't be invoked in constant expressions
  content = content.replaceAll('const Divider(color: Theme.of(context)', 'Divider(color: Theme.of(context)');
  content = content.replaceAll('const TextStyle(color: Theme.of(context)', 'TextStyle(color: Theme.of(context)');
  content = content.replaceAll('const Icon(Icons.send_rounded, color: Theme.of(context)', 'Icon(Icons.send_rounded, color: Theme.of(context)');
  
  // Fix: The argument type 'Color?' can't be assigned to the parameter type 'Color'
  content = content.replaceAll('color: isLiked ? Colors.red : Theme.of(context).textTheme.bodySmall?.color,', 'color: isLiked ? Colors.red : Theme.of(context).dividerColor,');
  content = content.replaceAll('color: Theme.of(context).textTheme.bodySmall?.color,', 'color: Theme.of(context).dividerColor,');
  
  // Fix specifically for activity_screen.dart:67 and 129
  content = content.replaceAll('Theme.of(context).textTheme.bodySmall?.color,', 'Theme.of(context).dividerColor,');
  content = content.replaceAll('Theme.of(context).textTheme.bodyMedium?.color,', 'Theme.of(context).dividerColor,');

  file.writeAsStringSync(content);
  print('Fixed errors in $path');
}

void main() {
  fixErrors('lib/screens/social_feed_screen.dart');
  fixErrors('lib/screens/activity_screen.dart');
  fixErrors('lib/screens/blocked_users_screen.dart');
}
