import React, { useState, useEffect } from 'react';
import { BrowserRouter, Routes, Route, Navigate, useNavigate } from 'react-router-dom';
import { Navbar, Nav, Container, Button } from 'react-bootstrap';
import { authApi } from './services/api';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import Users from './pages/Users';
import Cards from './pages/Cards';
import Terminals from './pages/Terminals';
import Transactions from './pages/Transactions';
import Keys from './pages/Keys';

const ProtectedRoute = ({ children, adminOnly = false }) => {
  const token = localStorage.getItem('token');
  if (!token) return <Navigate to="/login" replace />;
  
  if (adminOnly) {
    const storedUser = localStorage.getItem('user');
    if (storedUser) {
      try {
        const user = JSON.parse(storedUser);
        if (!user.is_admin) return <Navigate to="/dashboard" replace />;
      } catch (e) {}
    }
  }
  
  return children;
};

const LogoutButton = () => {
  const navigate = useNavigate();
  const handleLogout = () => {
    authApi.logout();
    authApi.clearUser();
    navigate('/login');
  };
  return <Button variant="outline-light" size="sm" onClick={handleLogout}>Выход</Button>;
};

const UserInfo = () => {
  const [user, setUser] = useState(null);
  
  useEffect(() => {
    // Сначала пробуем взять из localStorage
    const storedUser = localStorage.getItem('user');
    if (storedUser) {
      try {
        setUser(JSON.parse(storedUser));
      } catch (e) {}
    }
    // Потом запрашиваем с сервера
    authApi.me().then(data => {
      if (data.user) {
        setUser(data.user);
        localStorage.setItem('user', JSON.stringify(data.user));
      } else if (data.login) {
        setUser(data);
      }
    }).catch(err => console.error('User fetch error:', err));
  }, []);
  
  if (!user) return <span className="navbar-text me-3 text-light">Загрузка...</span>;
  
  return (
    <span className="navbar-text me-3 text-light">
      {user.login} ({user.is_admin ? 'админ' : 'пользователь'})
    </span>
  );
};

const Navigation = () => {
  const [user, setUser] = useState(null);
  
  useEffect(() => {
    const storedUser = localStorage.getItem('user');
    if (storedUser) {
      try {
        setUser(JSON.parse(storedUser));
      } catch (e) {}
    }
  }, []);
  
  const isAdmin = user?.is_admin === true;
  
  return (
    <Navbar variant="dark" expand="lg" className="mb-4">
      <Container>
        <Navbar.Brand href="/">Transport Card API</Navbar.Brand>
        <Nav className="me-auto">
          <Nav.Link href="/dashboard">Главная</Nav.Link>
          <Nav.Link href="/cards">Карты</Nav.Link>
          <Nav.Link href="/terminals">Терминалы</Nav.Link>
          <Nav.Link href="/transactions">Транзакции</Nav.Link>
          {isAdmin && <Nav.Link href="/users">Пользователи</Nav.Link>}
          {isAdmin && <Nav.Link href="/keys">Ключи</Nav.Link>}
        </Nav>
        <UserInfo />
        <LogoutButton />
      </Container>
    </Navbar>
  );
};

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<Login />} />
        <Route path="/dashboard" element={
          <ProtectedRoute>
            <Navigation />
            <Container><Dashboard /></Container>
          </ProtectedRoute>
        } />
        <Route path="/users" element={
          <ProtectedRoute adminOnly>
            <Navigation />
            <Container><Users /></Container>
          </ProtectedRoute>
        } />
        <Route path="/cards" element={
          <ProtectedRoute>
            <Navigation />
            <Container><Cards /></Container>
          </ProtectedRoute>
        } />
        <Route path="/terminals" element={
          <ProtectedRoute>
            <Navigation />
            <Container><Terminals /></Container>
          </ProtectedRoute>
        } />
        <Route path="/transactions" element={
          <ProtectedRoute>
            <Navigation />
            <Container><Transactions /></Container>
          </ProtectedRoute>
        } />
        <Route path="/keys" element={
          <ProtectedRoute adminOnly>
            <Navigation />
            <Container><Keys /></Container>
          </ProtectedRoute>
        } />
        <Route path="*" element={<Navigate to="/dashboard" replace />} />
      </Routes>
    </BrowserRouter>
  );
}

export default App;