import React, { useState, useEffect } from 'react';
import { Table, Button, Modal, Form, Alert, FormControl, InputGroup } from 'react-bootstrap';
import { cardsApi, keysApi } from '../services/api';

function Cards() {
  const [cards, setCards] = useState([]);
  const [keys, setKeys] = useState([]);
  const [showModal, setShowModal] = useState(false);
  const [editingCard, setEditingCard] = useState(null);
  const [formData, setFormData] = useState({ number: '', balance: 0, blocked: false, owner_name: '', key_id: '' });
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [searchId, setSearchId] = useState('');

  useEffect(() => { loadCards(); loadKeys(); }, []);

  const loadCards = async () => {
    try {
      const data = await cardsApi.list();
      const cardList = Array.isArray(data) ? data : (data.data || []);
      setCards(cardList);
    } catch (err) {
      setError(err.message);
    }
  };
  
  const loadKeys = async () => {
    try {
      const data = await keysApi.list();
      const keyList = Array.isArray(data) ? data : (data.data || []);
      setKeys(keyList);
    } catch (err) {
      // ignore
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      const payload = {
        number: formData.number,
        balance: parseInt(formData.balance),
        blocked: formData.blocked,
        owner_name: formData.owner_name,
        key_id: parseInt(formData.key_id)
      };
      if (editingCard) {
        await cardsApi.update(editingCard.id, payload);
      } else {
        await cardsApi.create(payload);
      }
      setShowModal(false);
      setEditingCard(null);
      setFormData({ number: '', balance: 0, blocked: false, owner_name: '', key_id: '' });
      loadCards();
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id) => {
    if (window.confirm('Удалить карту?')) {
      try {
        await cardsApi.delete(id);
        loadCards();
      } catch (err) {
        setError(err.message);
      }
    }
  };

  const openEdit = (card) => {
    setEditingCard(card);
    setFormData({ 
      number: card.number, 
      balance: card.balance, 
      blocked: card.blocked,
      owner_name: card.owner_name || '',
      key_id: card.key_id ? card.key_id.toString() : ''
    });
    setShowModal(true);
  };

  const filteredCards = searchId 
    ? cards.filter(c => c.id.toString() === searchId)
    : cards;

  return (
    <div>
      <div className="d-flex justify-content-between align-items-center mb-4">
        <h2>Карты</h2>
        <Button variant="primary" onClick={() => { setEditingCard(null); setFormData({ number: '', balance: 0, blocked: false, owner_name: '', key_id: '' }); setShowModal(true); }}>
          Добавить карту
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
            <th>Номер карты</th>
            <th>Баланс</th>
            <th>Владелец</th>
            <th>Заблокирована</th>
            <th>Действия</th>
          </tr>
        </thead>
        <tbody>
          {filteredCards.map(card => (
            <tr key={card.id}>
              <td>{card.id}</td>
              <td>{card.number}</td>
              <td>{card.balance}</td>
              <td>{card.owner_name}</td>
              <td>
                <span className={`badge ${!card.blocked ? 'badge-active' : 'badge-inactive'}`}>
                  {card.blocked ? 'Заблокирована' : 'Активна'}
                </span>
              </td>
              <td>
                <Button variant="outline-primary" size="sm" className="me-2" onClick={() => openEdit(card)}>Ред.</Button>
                <Button variant="outline-danger" size="sm" onClick={() => handleDelete(card.id)}>Удалить</Button>
              </td>
            </tr>
          ))}
        </tbody>
      </Table>

      <Modal show={showModal} onHide={() => setShowModal(false)}>
        <Modal.Header closeButton>
          <Modal.Title>{editingCard ? 'Редактировать карту' : 'Добавить карту'}</Modal.Title>
        </Modal.Header>
        <Form onSubmit={handleSubmit}>
          <Modal.Body>
            <Form.Group className="mb-3">
              <Form.Label>Номер карты</Form.Label>
              <Form.Control
                type="text"
                value={formData.number}
                onChange={(e) => setFormData({ ...formData, number: e.target.value })}
                required
              />
            </Form.Group>
            <Form.Group className="mb-3">
              <Form.Label>Баланс</Form.Label>
              <Form.Control
                type="number"
                value={formData.balance}
                onChange={(e) => setFormData({ ...formData, balance: parseInt(e.target.value) || 0})}
                required
              />
            </Form.Group>
            <Form.Group className="mb-3">
              <Form.Label>Имя владельца</Form.Label>
              <Form.Control
                type="text"
                value={formData.owner_name}
                onChange={(e) => setFormData({ ...formData, owner_name: e.target.value })}
                required
              />
            </Form.Group>
            <Form.Group className="mb-3">
              <Form.Label>Ключ</Form.Label>
              <Form.Select
                value={formData.key_id}
                onChange={(e) => setFormData({ ...formData, key_id: e.target.value })}
                required
              >
                <option value="">Выберите ключ</option>
                {keys.map(k => (
                  <option key={k.id} value={k.id}>{k.id} - {k.data}</option>
                ))}
              </Form.Select>
            </Form.Group>
            <Form.Group className="mb-3">
              <Form.Check
                type="checkbox"
                label="Заблокирована"
                checked={formData.blocked}
                onChange={(e) => setFormData({ ...formData, blocked: e.target.checked })}
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

export default Cards;