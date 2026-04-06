import axios from 'axios';

// Create axios instance with base configuration
const apiClient = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000/api',
  timeout: 30000, // 30 seconds
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor to add auth token
apiClient.interceptors.request.use(
  (config) => {
    const token = sessionStorage.getItem('auth_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
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
          error.config?.url?.includes('/auth/refresh');
        
        if (!isLoginPage && !isPublicAuthRequest) {
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
