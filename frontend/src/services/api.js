import API_URL from '../config';

const getToken = () => localStorage.getItem('token');

const handleResponse = async (response) => {
  if (!response.ok) {
    const error = await response.json().catch(() => ({ error: 'Unknown error' }));
    throw new Error(error.error || error.message || 'Request failed');
  }
  try {
    const data = await response.json();
    if (data === null) return [];
    if (Array.isArray(data)) return data;
    return data?.data || [];
  } catch {
    return [];
  }
};

const headers = () => {
  const h = { 'Content-Type': 'application/json' };
  const token = getToken();
  if (token) h['Authorization'] = `Bearer ${token}`;
  return h;
};

// ==================== AUTH API ====================
export const authApi = {
  login: async (login, password) => {
    const response = await fetch(`${API_URL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ login, password }),
    });
    if (!response.ok) {
      const error = await response.json().catch(() => ({ error: 'Unknown error' }));
      throw new Error(error.error || error.message || 'Login failed');
    }
    const data = await response.json();
    if (data.token) {
      localStorage.setItem('token', data.token);
      if (data.user) localStorage.setItem('user', JSON.stringify(data.user));
    }
    return data;
  },

  logout: () => {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
  },

  clearUser: () => {
    localStorage.removeItem('user');
  },

  me: async () => {
    const response = await fetch(`${API_URL}/auth/me`, {
      headers: headers(),
    });
    return handleResponse(response);
  },
};

// ==================== USERS API ====================
export const usersApi = {
  list: async () => {
    const response = await fetch(`${API_URL}/users`, { headers: headers() });
    return handleResponse(response);
  },

  get: async (id) => {
    const response = await fetch(`${API_URL}/users/${id}`, { headers: headers() });
    return handleResponse(response);
  },

  create: async (data) => {
    const response = await fetch(`${API_URL}/users`, {
      method: 'POST',
      headers: headers(),
      body: JSON.stringify(data),
    });
    return handleResponse(response);
  },

  update: async (id, data) => {
    const response = await fetch(`${API_URL}/users/${id}`, {
      method: 'PUT',
      headers: headers(),
      body: JSON.stringify(data),
    });
    return handleResponse(response);
  },

  delete: async (id) => {
    const response = await fetch(`${API_URL}/users/${id}`, {
      method: 'DELETE',
      headers: headers(),
    });
    return handleResponse(response);
  },
};

// ==================== CARDS API ====================
export const cardsApi = {
  list: async () => {
    const response = await fetch(`${API_URL}/cards`, { headers: headers() });
    return handleResponse(response);
  },

  get: async (id) => {
    const response = await fetch(`${API_URL}/cards/${id}`, { headers: headers() });
    return handleResponse(response);
  },

  create: async (data) => {
    const response = await fetch(`${API_URL}/cards`, {
      method: 'POST',
      headers: headers(),
      body: JSON.stringify(data),
    });
    return handleResponse(response);
  },

  update: async (id, data) => {
    const response = await fetch(`${API_URL}/cards/${id}`, {
      method: 'PUT',
      headers: headers(),
      body: JSON.stringify(data),
    });
    return handleResponse(response);
  },

  delete: async (id) => {
    const response = await fetch(`${API_URL}/cards/${id}`, {
      method: 'DELETE',
      headers: headers(),
    });
    return handleResponse(response);
  },

  getByUid: async (uid) => {
    const response = await fetch(`${API_URL}/cards/by-uid/${uid}`, { 
      headers: headers() 
    });
    return handleResponse(response);
  },
};

// ==================== TERMINALS API ====================
export const terminalsApi = {
  list: async () => {
    const response = await fetch(`${API_URL}/terminals`, { headers: headers() });
    return handleResponse(response);
  },

  get: async (id) => {
    const response = await fetch(`${API_URL}/terminals/${id}`, { headers: headers() });
    return handleResponse(response);
  },

  create: async (data) => {
    const response = await fetch(`${API_URL}/terminals`, {
      method: 'POST',
      headers: headers(),
      body: JSON.stringify(data),
    });
    return handleResponse(response);
  },

  update: async (id, data) => {
    const response = await fetch(`${API_URL}/terminals/${id}`, {
      method: 'PUT',
      headers: headers(),
      body: JSON.stringify(data),
    });
    return handleResponse(response);
  },

  delete: async (id) => {
    const response = await fetch(`${API_URL}/terminals/${id}`, {
      method: 'DELETE',
      headers: headers(),
    });
    return handleResponse(response);
  },

  authorize: async (cardNumber, amount, terminalId) => {
    const response = await fetch(`${API_URL}/terminals/authorize`, {
      method: 'POST',
      headers: headers(),
      body: JSON.stringify({ card_number: cardNumber, amount, terminal_id: terminalId }),
    });
    return handleResponse(response);
  },

  getKeys: async () => {
    const response = await fetch(`${API_URL}/terminals/keys`, { headers: headers() });
    return handleResponse(response);
  },
};

// ==================== TRANSACTIONS API ====================
export const transactionsApi = {
  list: async () => {
    const response = await fetch(`${API_URL}/transactions`, { headers: headers() });
    return handleResponse(response);
  },

  create: async (data) => {
    const response = await fetch(`${API_URL}/transactions`, {
      method: 'POST',
      headers: headers(),
      body: JSON.stringify(data),
    });
    return handleResponse(response);
  },
};

// ==================== KEYS API ====================
export const keysApi = {
  list: async () => {
    const response = await fetch(`${API_URL}/keys`, { headers: headers() });
    return handleResponse(response);
  },

  get: async (id) => {
    const response = await fetch(`${API_URL}/keys/${id}`, { headers: headers() });
    return handleResponse(response);
  },

  create: async (data) => {
    const response = await fetch(`${API_URL}/keys`, {
      method: 'POST',
      headers: headers(),
      body: JSON.stringify(data),
    });
    return handleResponse(response);
  },

  update: async (id, data) => {
    const response = await fetch(`${API_URL}/keys/${id}`, {
      method: 'PUT',
      headers: headers(),
      body: JSON.stringify(data),
    });
    return handleResponse(response);
  },

  delete: async (id) => {
    const response = await fetch(`${API_URL}/keys/${id}`, {
      method: 'DELETE',
      headers: headers(),
    });
    return handleResponse(response);
  },
};