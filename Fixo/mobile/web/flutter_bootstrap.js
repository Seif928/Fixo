{{flutter_js}}
{{flutter_build_config}}

// Retire only Flutter's old offline shell; keep Firebase's push worker intact.
(async () => {
  try {
    if ('serviceWorker' in navigator) {
      const expected = new URL('flutter_service_worker.js', document.baseURI);
      const registrations = await navigator.serviceWorker.getRegistrations();
      await Promise.all(registrations.filter(registration => {
        const worker = registration.active || registration.waiting || registration.installing;
        if (!worker) return false;
        const url = new URL(worker.scriptURL);
        return url.origin === expected.origin && url.pathname === expected.pathname;
      }).map(registration => registration.unregister()));
      if (typeof caches !== 'undefined') {
        await Promise.all(['flutter-app-cache', 'flutter-temp-cache', 'flutter-app-manifest']
          .map(name => caches.delete(name)));
      }
    }
  } catch (_) {
    console.warn('FIXO asset cache refresh was unavailable. Continuing startup.');
  }
  return _flutter.loader.load();
})();
