import { createInertiaApp } from '@inertiajs/vue3';
import { defineAsyncComponent } from 'vue';
import { initializeTheme } from '@/composables/useAppearance';
import { initializeFlashToast } from '@/lib/flashToast';

const appName = import.meta.env.VITE_APP_NAME || 'Laravel';

// Cargamos los layouts de forma asíncrona para que no bloqueen la inicialización de Vue
const AppLayout = defineAsyncComponent(() => import('@/layouts/AppLayout.vue'));
const AuthLayout = defineAsyncComponent(() => import('@/layouts/AuthLayout.vue'));
const SettingsLayout = defineAsyncComponent(() => import('@/layouts/settings/Layout.vue'));

createInertiaApp({
    title: (title) => (title ? `${title} - ${appName}` : appName),
    layout: (name) => {
        const page = name.toLowerCase();
        switch (true) {
            case page === 'welcome':
                return null;
            case page.startsWith('auth/'):
                return AuthLayout;
            case page.startsWith('settings/'):
                return [AppLayout, SettingsLayout];
            default:
                return AppLayout;
        }
    },
    progress: {
        color: '#4B5563',
    },
});

initializeTheme();
initializeFlashToast();