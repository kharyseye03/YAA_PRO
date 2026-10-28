# Annotations J2ObjC, référencées par Guava — lui-même tiré par
# DataStore. Elles ne servent qu'à la traduction Java → Objective-C et
# ne sont jamais présentes à l'exécution sur Android : R8 s'arrête
# dessus sans ces deux lignes.
-dontwarn com.google.j2objc.annotations.ReflectionSupport
-dontwarn com.google.j2objc.annotations.RetainedWith
