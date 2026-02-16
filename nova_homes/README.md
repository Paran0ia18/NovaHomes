# NovaHomes

App Flutter de alquiler vacacional de ultra-lujo (estilo Airbnb Plus), enfocada en UI/UX premium, flujo completo de reserva y arquitectura preparada para backend real.

## Estado del proyecto

- Estado actual: MVP avanzado de portfolio
- Version: `1.0.0+1`
- Plataforma principal: Android
- iOS: estructura preparada para integracion posterior

## Funcionalidades principales

- Onboarding visual premium
- Login y Sign Up separados (email/password)
- Inicio de sesion social con Google y Apple (segun plataforma/configuracion)
- Home Explore con:
  - buscador
  - categorias
  - ordenaciones
  - filtros avanzados
  - query compuesta para portfolio (`Mallorca + <=500 + pool`)
- Ficha de propiedad con Hero image, amenities y CTA de reserva
- Calendario de reserva con seleccion de rango (`table_calendar`)
- Checkout con desglose de costes y flujo de pago
- Pagos en modo demo (sin cobro real) y opcion real con Stripe test
- Persistencia de favoritos y reservas en Firestore (si esta configurado)
- Perfil con edicion de nombre y avatar por URL
- Pantallas adicionales de Saved, Trips e Inbox

## Stack tecnico

- Flutter / Dart
- Firebase Core
- Firebase Auth
- Cloud Firestore
- Cloud Functions
- Firebase Storage
- flutter_stripe
- table_calendar
- google_fonts
- google_sign_in
- sign_in_with_apple
- image_picker

## Arquitectura (resumen)

- `lib/screens`: pantallas principales de la app
- `lib/models`: modelos de dominio (`Property`, `Booking`, etc.)
- `lib/services`: auth, firestore, pagos, media de perfil
- `lib/state`: estado global de UI y datos de sesion
- `lib/widgets`: componentes reutilizables
- `lib/theme`: design system (tipografia, colores, estilos)
- `functions/src`: logica server-side para booking/pago real

## Integraciones y fuentes de datos

- Firestore:
  - `properties` (datos de inmuebles, amenities en array, location en mapa)
  - `users/{uid}` (perfil y favoritos)
  - `bookings` y `users/{uid}/bookings`
- Cloud Functions:
  - `createBooking` (valida disponibilidad, calcula total y crea PaymentIntent)
- Stripe:
  - PaymentSheet en modo test para pagos reales de prueba
- Fallback:
  - si Firestore no responde, la app usa `mockProperties`

## Configuracion local

### 1) Requisitos

- Flutter SDK compatible con `sdk: ^3.10.1`
- Android Studio o VS Code
- Proyecto Firebase Android configurado

### 2) Firebase Android

- Coloca `google-services.json` en `android/app/google-services.json`
- Activa en Firebase Auth:
  - Email/Password
  - Google (si vas a usarlo)
  - Apple (si vas a usarlo en iOS/macOS)

### 3) Modo demo vs modo real

- Por defecto:
  - pagos en demo (`USE_REAL_PAYMENTS=false`)
  - sync remoto de avatar desactivado (`ENABLE_PROFILE_REMOTE_SYNC=false`)
  - subida de avatar a Storage desactivada (`ENABLE_STORAGE_UPLOADS=false`)

- Ejemplo modo demo:
  - `flutter run --dart-define=USE_REAL_PAYMENTS=false`

- Ejemplo Stripe test (real de prueba):
  - `flutter run --dart-define=USE_REAL_PAYMENTS=true --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_xxx`

### 4) Comandos utiles

- `flutter pub get`
- `flutter analyze`
- `flutter test`
- `flutter run`
- `flutter build appbundle --release`

### 5) Cloud Functions (opcional para pago real)

- `cd functions`
- `npm install`
- `npm run build`
- `npm run serve`
- `npm run deploy`

## Configuracion Firestore relevante

- Reglas: `firestore.rules`
- Indices: `firestore.indexes.json`
- Query compuesta incluida para demostrar indices en portfolio:
  - ciudad + precio maximo + amenities + orden

## Seguridad antes de publicar

- No subir claves privadas reales al repositorio
- Usar variables de entorno para Stripe y secretos server-side
- Revisar historial Git si alguna key estuvo expuesta
- Para portfolio, recomendado repo privado hasta sanear secretos

## Nota legal

NovaHomes es un proyecto de portfolio/demostracion. No representa una plataforma comercial en produccion.
