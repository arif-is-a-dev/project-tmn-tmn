import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      '/api': {
        target: 'http://localhost:8000',
        changeOrigin: true,
        // Forecast endpoints (especially custom range up to 36 months × 11 products)
        // can take 30-60s for recursive model inference. The frontend fetch timeout
        // is 60s (FORECAST_TIMEOUT_MS); give the proxy a matching buffer.
        timeout: 65_000,
      },
    },
  },
});
