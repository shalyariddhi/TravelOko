import 'dart:io';

void main() {
  final dir = Directory('lib');
  for (final file in dir.listSync(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      final lines = file.readAsLinesSync();
      int containerLine = -1;
      int colorLine = -1;
      int decoLine = -1;
      
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.contains('Container(') || line.contains('AnimatedContainer(')) {
          containerLine = i;
          colorLine = -1;
          decoLine = -1;
          
          for (int j = i + 1; j < lines.length && j < i + 20; j++) {
            final innerLine = lines[j];
            
            if (innerLine.trimLeft().startsWith('color:')) {
               if (colorLine == -1) colorLine = j;
            }
            if (innerLine.trimLeft().startsWith('decoration:')) {
               if (decoLine == -1) decoLine = j;
            }
            
            if (colorLine != -1 && decoLine != -1) {
                final cIndent = lines[colorLine].length - lines[colorLine].trimLeft().length;
                final dIndent = lines[decoLine].length - lines[decoLine].trimLeft().length;
                if (cIndent == dIndent) {
                   print(file.path + ': container at line ' + (containerLine+1).toString() + ', color at ' + (colorLine+1).toString() + ', decoration at ' + (decoLine+1).toString());
                   break;
                }
            }
          }
        }
      }
    }
  }
}