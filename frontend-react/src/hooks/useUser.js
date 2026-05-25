import { useState, useEffect } from 'react';

export const useIsAdmin = () => {
  const [isAdmin, setIsAdmin] = useState(false);
  
  useEffect(() => {
    const storedUser = localStorage.getItem('user');
    if (storedUser) {
      try {
        const user = JSON.parse(storedUser);
        setIsAdmin(user.is_admin === true);
      } catch (e) {
        setIsAdmin(false);
      }
    }
  }, []);
  
  return isAdmin;
};