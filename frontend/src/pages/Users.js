import React, { useState, useEffect } from 'react';
import { Table, Button, Modal, Form, Alert, FormControl, InputGroup } from 'react-bootstrap';
import { usersApi } from '../services/api';

function Users() {
  const [users, setUsers] = useState([]);
  const [showModal, setShowModal] = useState(false);
  const [editingUser, setEditingUser] = useState(null);
  const [formData, setFormData] = useState({ login: '', password: '', role: 'user' });
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [searchId, setSearchId] = useState('');

  useEffect(() => { loadUsers(); }, []);

  const loadUsers = async () => {
    try {
      const data = await usersApi.list();
      setUsers(data);
    } catch (err) {
      setError(err.message);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      if (editingUser) {
        await usersApi.update(editingUser.id, formData);
      } else {
        await usersApi.create(formData);
      }
      setShowModal(false);
      setEditingUser(null);
      setFormData({ login: '', password: '', role: 'user' });
      loadUsers();
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id) => {
    if (window.confirm('Удалить пользователя?')) {
      try {
        await usersApi.delete(id);
        loadUsers();
      } catch (err) {
        setError(err.message);
      }
    }
  };

  const openEdit = (user) => {
    setEditingUser(user);
    setFormData({ login: user.login, password: '', role: user.role });
    setShowModal(true);
  };

  const filteredUsers = searchId 
    ? users.filter(u => u.id.toString() === searchId)
    : users;

  return (
    <div>
      <div className="d-flex justify-content-between align-items-center mb-4">
        <h2>Пользователи</h2>
        <Button variant="primary" onClick={() => { setEditingUser(null); setFormData({ login: '', password: '', role: 'user' }); setShowModal(true); }}>
          Добавить
        </Button>
      </div>

      <InputGroup className="mb-3" style={{ maxWidth: 200 }}>
        <FormControl
          placeholder="Поиск по ID"
          value={searchId}
          onChange={(e) => setSearchId(e.target.value)}
        />
      </InputGroup>

      {error && <Alert variant="danger" className="mb-3">{error}</Alert>}

      <Table responsive>
        <thead>
          <tr>
            <th>ID</th>
            <th>Логин</th>
            <th>Роль</th>
            <th>Действия</th>
          </tr>
        </thead>
        <tbody>
          {filteredUsers.map(user => (
            <tr key={user.id}>
              <td>{user.id}</td>
              <td>{user.login}</td>
              <td>{user.role}</td>
              <td>
                <Button variant="outline-primary" size="sm" className="me-2" onClick={() => openEdit(user)}>Ред.</Button>
                <Button variant="outline-danger" size="sm" onClick={() => handleDelete(user.id)}>Удалить</Button>
              </td>
            </tr>
          ))}
        </tbody>
      </Table>

      <Modal show={showModal} onHide={() => setShowModal(false)}>
        <Modal.Header closeButton>
          <Modal.Title>{editingUser ? 'Редактировать' : 'Добавить пользователя'}</Modal.Title>
        </Modal.Header>
        <Form onSubmit={handleSubmit}>
          <Modal.Body>
            <Form.Group className="mb-3">
              <Form.Label>Логин</Form.Label>
              <Form.Control
                type="text"
                value={formData.login}
                onChange={(e) => setFormData({ ...formData, login: e.target.value })}
                required
              />
            </Form.Group>
            <Form.Group className="mb-3">
              <Form.Label>Пароль {editingUser && '(оставьте пустым чтобы не менять)'}</Form.Label>
              <Form.Control
                type="password"
                value={formData.password}
                onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                required={!editingUser}
              />
            </Form.Group>
            <Form.Group className="mb-3">
              <Form.Label>Роль</Form.Label>
              <Form.Select
                value={formData.role}
                onChange={(e) => setFormData({ ...formData, role: e.target.value })}
              >
                <option value="user">User</option>
                <option value="admin">Admin</option>
              </Form.Select>
            </Form.Group>
          </Modal.Body>
          <Modal.Footer>
            <Button variant="secondary" onClick={() => setShowModal(false)}>Отмена</Button>
            <Button variant="primary" type="submit" disabled={loading}>
              {loading ? 'Сохранение...' : 'Сохранить'}
            </Button>
          </Modal.Footer>
        </Form>
      </Modal>
    </div>
  );
}

export default Users;