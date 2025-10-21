import React, { useEffect, useState } from 'react';
import { authService, type User } from '../../services/authService';

export default function Navigation() {
  const [user, setUser] = useState<User | null>(null);

  useEffect(() => {
    setUser(authService.getUser());
  }, []);

  return (
    <nav className="bg-white shadow-sm sticky top-0 z-50">
      <div className="max-w-7xl mx-auto px-4">
        <div className="flex justify-between items-center h-16">
          <a href="/" className="text-2xl font-bold text-emerald-600">
            OptimealOne
          </a>
          <div className="flex items-center gap-4">
            {user ? (
              <>
                <span className="text-sm text-gray-700">{user.email}</span>
                <a href="/dashboard" className="text-gray-700 hover:text-emerald-600">
                  Dashboard
                </a>
                <button
                  onClick={() => {
                    authService.logout();
                    window.location.href = '/';
                  }}
                  className="px-4 py-2 text-gray-700 hover:text-emerald-600"
                >
                  Deconnexion
                </button>
              </>
            ) : (
              <>
                <a href="/auth/login" className="text-gray-700 hover:text-emerald-600">
                  Connexion
                </a>
                <a href="/auth/register" className="px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700">
                  Inscription
                </a>
              </>
            )}
          </div>
        </div>
      </div>
    </nav>
  );
}