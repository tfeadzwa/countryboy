import apiClient from './axios';
import { jwtDecode } from 'jwt-decode';

export interface LoginCredentials {
  // Backend accepts either username or email in this field.
  username: string;
  password: string;
}

export interface LoginResponse {
  token: string;
  user: {
    id: string;
    username: string;
    email?: string | null;
    full_name?: string;
    depot_id?: string;
    roles?: string[]; // Backend returns array of role names
  };
  message: string;
}

export interface DecodedToken {
  userId: string;
  iat: number;
  exp: number;
}

export interface User {
  id: string;
  username: string;
  email?: string | null;
  full_name?: string;
  depot_id?: string;
  roles: string[]; // Store roles array
}

class AuthService {
  /**
   * Login with username and password
   */
  async login(credentials: LoginCredentials): Promise<LoginResponse> {
    const response = await apiClient.post<LoginResponse>('/auth/login', credentials);
    return response.data;
  }

  /**
   * Logout - clear session storage
   */
  logout(): void {
    sessionStorage.removeItem('auth_token');
    sessionStorage.removeItem('user_data');
  }

  /**
   * Store authentication token and user data
   */
  storeAuth(token: string, user: User): void {
    sessionStorage.setItem('auth_token', token);
    sessionStorage.setItem('user_data', JSON.stringify({
      id: user.id,
      username: user.username,
      email: user.email,
      full_name: user.full_name,
      depot_id: user.depot_id,
      roles: user.roles || [], // Ensure roles array is stored
    }));
  }

  /**
   * Get stored authentication token
   */
  getToken(): string | null {
    return sessionStorage.getItem('auth_token');
  }

  /**
   * Get stored user data
   */
  getUser(): User | null {
    const userData = sessionStorage.getItem('user_data');
    if (!userData) return null;
    
    try {
      return JSON.parse(userData);
    } catch {
      return null;
    }
  }

  /**
   * Check if user is authenticated
   */
  isAuthenticated(): boolean {
    const token = this.getToken();
    if (!token) return false;

    try {
      const decoded = jwtDecode<DecodedToken>(token);
      // Check if token is expired (exp is in seconds, Date.now() is in milliseconds)
      const isExpired = decoded.exp * 1000 < Date.now();
      
      if (isExpired) {
        this.logout();
        return false;
      }
      
      return true;
    } catch {
      // Invalid token
      this.logout();
      return false;
    }
  }

  /**
   * Decode JWT token to get user info
   */
  decodeToken(token: string): DecodedToken | null {
    try {
      return jwtDecode<DecodedToken>(token);
    } catch {
      return null;
    }
  }
}

export const authService = new AuthService();
