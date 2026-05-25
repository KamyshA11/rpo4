import React, { useState, useEffect } from 'react';
import { Table, Button, Modal, Form, Alert, FormControl, InputGroup } from 'react-bootstrap';
import { keysApi } from '../services/api';

function Keys() {
  const [keys, setKeys] = useState([]);
  const [showModal, setShowModal] = useState(false);
  const [editingKey, setEditingKey] = useState(null);
  const [formData, setFormData] = useState({ data: '' });
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [searchId, setSearchId] = useState('');

  useEffect(() => { loadKeys(); }, []);

  const loadKeys = async () => {
    try {
      const data = await keysApi.list();
      const keyList = Array.isArray(data) ? data : (data.data || []);
      setKeys(keyList);
    } catch (err) {
      setError(err.message);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      if (editingKey) {
        await keysApi.update(editingKey.id, formData);
      } else {
        await keysApi.create(formData);
      }
      setShowModal(false);
      setEditingKey(null);
      setFormData({ data: '' });
      loadKeys();
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id) => {
    if (window.confirm('Удалить ключ?')) {
      try {
        await keysApi.delete(id);
        loadKeys();
      } catch (err) {
        setError(err.message);
      }
    }
  };

  const openEdit = (key) => {
    setEditingKey(key);
    setFormData({ data: key.data });
    setShowModal(true);
  };

  const filteredKeys = searchId 
    ? keys.filter(k => k.id.toString() === searchId)
    : keys;

  return (
    <div>
      <div className="d-flex justify-content-between align-items-center mb-4">
        <h2>Ключи</h2>
        <Button variant="primary" onClick={() => { setEditingKey(null); setFormData({ data: '' }); setShowModal(true); }}>
          Добавить ключ
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
            <th>Ключ</th>
            <th>Действия</th>
          </tr>
        </thead>
        <tbody>
          {filteredKeys.map(key => (
            <tr key={key.id}>
              <td>{key.id}</td>
              <td><code>{key.data}</code></td>
              <td>
                <Button variant="outline-primary" size="sm" className="me-2" onClick={() => openEdit(key)}>Ред.</Button>
                <Button variant="outline-danger" size="sm" onClick={() => handleDelete(key.id)}>Удалить</Button>
              </td>
            </tr>
          ))}
        </tbody>
      </Table>

      <Modal show={showModal} onHide={() => setShowModal(false)}>
        <Modal.Header closeButton>
          <Modal.Title>{editingKey ? 'Редактировать ключ' : 'Добавить ключ'}</Modal.Title>
        </Modal.Header>
        <Form onSubmit={handleSubmit}>
          <Modal.Body>
            <Form.Group className="mb-3">
              <Form.Label>Ключ</Form.Label>
              <Form.Control
                as="textarea"
                rows={3}
                value={formData.data}
                onChange={(e) => setFormData({ ...formData, data: e.target.value })}
                required
              />
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

export default Keys;