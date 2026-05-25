import React, { useState, useEffect } from 'react';
import { Table, Button, Modal, Form, Alert, FormControl, InputGroup } from 'react-bootstrap';
import { terminalsApi } from '../services/api';

function Terminals() {
  const [terminals, setTerminals] = useState([]);
  const [showModal, setShowModal] = useState(false);
  const [editingTerminal, setEditingTerminal] = useState(null);
  const [formData, setFormData] = useState({ name: '', serial: '', address: '' });
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [searchId, setSearchId] = useState('');

  useEffect(() => { loadTerminals(); }, []);

  const loadTerminals = async () => {
    try {
      const data = await terminalsApi.list();
      const termList = Array.isArray(data) ? data : (data.data || []);
      setTerminals(termList);
    } catch (err) {
      setError(err.message);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      if (editingTerminal) {
        await terminalsApi.update(editingTerminal.id, formData);
      } else {
        await terminalsApi.create(formData);
      }
      setShowModal(false);
      setEditingTerminal(null);
      setFormData({ name: '', serial: '', address: '' });
      loadTerminals();
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id) => {
    if (window.confirm('Удалить терминал?')) {
      try {
        await terminalsApi.delete(id);
        loadTerminals();
      } catch (err) {
        setError(err.message);
      }
    }
  };

  const openEdit = (terminal) => {
    setEditingTerminal(terminal);
    setFormData({ name: terminal.name, serial: terminal.serial, address: terminal.address });
    setShowModal(true);
  };

  const filteredTerminals = searchId 
    ? terminals.filter(t => t.id.toString() === searchId)
    : terminals;

  return (
    <div>
      <div className="d-flex justify-content-between align-items-center mb-4">
        <h2>Терминалы</h2>
        <Button variant="primary" onClick={() => { setEditingTerminal(null); setFormData({ name: '', serial: '', address: '' }); setShowModal(true); }}>
          Добавить терминал
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
            <th>Название</th>
            <th>Серийный номер</th>
            <th>Адрес</th>
            <th>Действия</th>
          </tr>
        </thead>
        <tbody>
          {filteredTerminals.map(terminal => (
            <tr key={terminal.id}>
              <td>{terminal.id}</td>
              <td>{terminal.name}</td>
              <td>{terminal.serial}</td>
              <td>{terminal.address}</td>
              <td>
                <Button variant="outline-primary" size="sm" className="me-2" onClick={() => openEdit(terminal)}>Ред.</Button>
                <Button variant="outline-danger" size="sm" onClick={() => handleDelete(terminal.id)}>Удалить</Button>
              </td>
            </tr>
          ))}
        </tbody>
      </Table>

      <Modal show={showModal} onHide={() => setShowModal(false)}>
        <Modal.Header closeButton>
          <Modal.Title>{editingTerminal ? 'Редактировать терминал' : 'Добавить терминал'}</Modal.Title>
        </Modal.Header>
        <Form onSubmit={handleSubmit}>
          <Modal.Body>
            <Form.Group className="mb-3">
              <Form.Label>Название</Form.Label>
              <Form.Control
                type="text"
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                required
              />
            </Form.Group>
            <Form.Group className="mb-3">
              <Form.Label>Серийный номер</Form.Label>
              <Form.Control
                type="text"
                value={formData.serial}
                onChange={(e) => setFormData({ ...formData, serial: e.target.value })}
                required
              />
            </Form.Group>
            <Form.Group className="mb-3">
              <Form.Label>Адрес</Form.Label>
              <Form.Control
                type="text"
                value={formData.address}
                onChange={(e) => setFormData({ ...formData, address: e.target.value })}
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

export default Terminals;