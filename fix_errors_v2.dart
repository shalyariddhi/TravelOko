import 'dart:io';

void main() {
  // Social Feed Fixes
  final socialFeedFile = File('lib/screens/social_feed_screen.dart');
  if (socialFeedFile.existsSync()) {
    String sfContent = socialFeedFile.readAsStringSync();
    sfContent = sfContent.replaceAll('const BoxDecoration(\n            gradient: LinearGradient(\n              begin: Alignment.topLeft,\n              end: Alignment.bottomRight,\n              colors: [Theme.of(context).scaffoldBackgroundColor, Theme.of(context).scaffoldBackgroundColor],', 
                                     'BoxDecoration(\n            gradient: LinearGradient(\n              begin: Alignment.topLeft,\n              end: Alignment.bottomRight,\n              colors: [Theme.of(context).scaffoldBackgroundColor, Theme.of(context).scaffoldBackgroundColor],');
    sfContent = sfContent.replaceAll('const LinearGradient(\n              begin: Alignment.topLeft,\n              end: Alignment.bottomRight,\n              colors: [Theme.of(context).scaffoldBackgroundColor, Theme.of(context).scaffoldBackgroundColor],', 
                                     'LinearGradient(\n              begin: Alignment.topLeft,\n              end: Alignment.bottomRight,\n              colors: [Theme.of(context).scaffoldBackgroundColor, Theme.of(context).scaffoldBackgroundColor],');
    sfContent = sfContent.replaceAll('const BoxDecoration(\n            color: Theme.of(context).scaffoldBackgroundColor,', 'BoxDecoration(\n            color: Theme.of(context).scaffoldBackgroundColor,');
    sfContent = sfContent.replaceAll('colors: [Theme.of(context).scaffoldBackgroundColor, Theme.of(context).scaffoldBackgroundColor]', 'colors: [Theme.of(context).scaffoldBackgroundColor, Theme.of(context).scaffoldBackgroundColor]');
    
    // There are some other const LinearGradients
    sfContent = sfContent.replaceAll('gradient: const LinearGradient(colors: [Colors.amber, Color(0xFFED8F03)])', 'gradient: LinearGradient(colors: [Colors.amber, Color(0xFFED8F03)])');
    
    socialFeedFile.writeAsStringSync(sfContent);
  }

  // Settings Fixes
  final settingsFile = File('lib/screens/settings_screen.dart');
  if (settingsFile.existsSync()) {
    String sContent = settingsFile.readAsStringSync();
    // trailing: const Icon(Icons.chevron_right, color: Theme.of(context).textTheme.bodyMedium?.color)
    sContent = sContent.replaceAll('const Icon(Icons.chevron_right, color: Theme.of(context).textTheme.bodyMedium?.color)', 
                                   'Icon(Icons.chevron_right, color: Theme.of(context).textTheme.bodyMedium?.color)');
    // Text('Private Account', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium?.color)) - oh wait
    sContent = sContent.replaceAll('context, user, firebaseService', 'context, user, firebaseService'); // Context error: it's not defined
    // Wait, the context undefined error:
    // lib/screens/settings_screen.dart:171:65 - undefined_identifier 'context'
    // Let's just fix .color[800] if it was incorrectly mapped to .color[800]
    
    settingsFile.writeAsStringSync(sContent);
  }
}
