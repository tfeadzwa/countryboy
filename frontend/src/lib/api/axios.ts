import axios from 'axios';
import { getApiBaseUrl } from './base-url';

// Create axios instance with base configuration
const apiClient = axios.create({
  baseURL: getApiBaseUrl(),
  timeout: 30000, // 30 seconds
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor to add auth token (+ depot scope for SUPER_ADMIN mutations)
apiClient.interceptors.request.use(
  (config) => {
    const token = sessionStorage.getItem('auth_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }

    // Super admins must send depot context on POST/PUT/PATCH/DELETE.
    // Prefer an explicit header from the caller; otherwise use navbar selection.
    const method = (config.method || 'get').toUpperCase();
    const isMutating = ['POST', 'PUT', 'PATCH', 'DELETE'].includes(method);
    if (isMutating && !config.headers['x-depot-id']) {
      const selectedDepotId = sessionStorage.getItem('selected_depot_id');
      if (selectedDepotId) {
        config.headers['x-depot-id'] = selectedDepotId;
      }
    }

    // Let the browser set multipart boundary — default application/json breaks file uploads.
    if (config.data instanceof FormData) {
      delete config.headers['Content-Type'];
    }

    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response interceptor to handle errors
apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response) {
      // Handle 401 Unauthorized - token expired or invalid
      if (error.response.status === 401) {
        // Don't auto-redirect if we're on the login page or it's a login attempt
        const isLoginPage = window.location.pathname === '/login';
        const isPublicAuthRequest =
          error.config?.url?.includes('/auth/login') ||
          error.config?.url?.includes('/auth/forgot-password') ||
          error.config?.url?.includes('/auth/reset-password') ||
          error.config?.url?.includes('/auth/refresh') ||
          error.config?.url?.includes('/public/');
        
        const isPublicPage = window.location.pathname.startsWith('/verify/');

        if (!isLoginPage && !isPublicAuthRequest && !isPublicPage) {
          // Clear session storage
          sessionStorage.removeItem('auth_token');
          sessionStorage.removeItem('user_data');
          
          // Redirect to login
          window.location.href = '/login';
        }
      }
      
      // Extract error message from response
      const message = error.response.data?.message || error.response.data?.error || 'An error occurred';
      return Promise.reject(new Error(message));
    } else if (error.request) {
      // Network error
      return Promise.reject(new Error('Network error. Please check your connection.'));
    } else {
      // Other errors
      return Promise.reject(new Error('An unexpected error occurred.'));
    }
  }
);

export default apiClient;
