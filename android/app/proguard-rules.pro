# JSCH rules
# Keep all JSCH classes to avoid ClassNotFoundException when loaded via reflection
-keep class com.jcraft.jsch.** { *; }
-dontwarn com.jcraft.jsch.**

# Bouncy Castle rules
# JSCH 0.2.x uses Bouncy Castle for various cryptographic operations
-keep class org.bouncycastle.** { *; }
-dontwarn org.bouncycastle.**

# Also keep the JCE providers that JSCH might look for
-keep class javax.crypto.** { *; }
-dontwarn javax.crypto.**
