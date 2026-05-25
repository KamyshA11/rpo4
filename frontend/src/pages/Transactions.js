import React, { useState, useEffect } from 'react';
import { Table, Button, Modal, Form, Alert, FormControl, InputGroup } from 'react-bootstrap';
import { transactionsApi, cardsApi, terminalsApi } from '../services/api';
import { useIsAdmin } from '../hooks/useUser';

function Transactions() {
  const [transactions, setTransactions] = useState([]);
  const [cards, setCards] = useState([]);
  const [terminals, setTerminals] = useState([]);
  const [showModal, setShowModal] = useState(false);
  const [formData, setFormData] = useState({ amount: '', card_id: '', terminal_id: '' });
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [searchId, setSearchId] = useState('');
  const isAdmin = useIsAdmin();

  useEffect(() => { 
    loadTransactions(); 
    loadCards();
    loadTerminals();
  }, []);

  const loadTransactions = async () => {
    try {
      const data = await transactionsApi.list();
      const txList = Array.isArray(data) ? data : (data.data || []);
      txList.sort((a, b) => a.id - b.id);
      setTransactions(txList);
    } catch (err) {
      setError(err.message);
    }
  };

  const loadCards = async () => {
    try {
      const data = await cardsApi.list();
      const cardList = Array.isArray(data) ? data : (data.data || []);
      setCards(cardList);
    } catch (err) {
      // ignore
    }
  };

  const loadTerminals = async () => {
    try {
      const data = await terminalsApi.list();
      const termList = Array.isArray(data) ? data : (data.data || []);
      setTerminals(termList);
    } catch (err) {
      // ignore
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      await transactionsApi.create({
        amount: parseInt(formData.amount),
        card_id: parseInt(formData.card_id),
        terminal_id: parseInt(formData.terminal_id)
      });
      setShowModal(false);
      setFormData({ amount: '', card_id: '', terminal_id: '' });
      loadTransactions();
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const filteredTransactions = searchId 
    ? transactions.filter(t => t.id.toString() === searchId)
    : transactions;

  return (
    <div>
      <div className="d-flex justify-content-between align-items-center mb-4">
        <h2>Транзакции</h2>
        <Button variant="primary" onClick={() => setShowModal(true)}>
          Создать транзакцию
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
            <th>ID карты</th>
            <th>ID терминала</th>
            <th>Сумма</th>
            <th>Дата</th>
          </tr>
        </thead>
        <tbody>
          {filteredTransactions.length === 0 ? (
            <tr><td colSpan="5" className="text-center text-muted">Нет транзакций</td></tr>
          ) : (
            filteredTransactions.map(tx => (
              <tr key={tx.id}>
                <td>{tx.id}</td>
                <td>{tx.card_id}</td>
                <td>{tx.terminal_id}</td>
                <td>{tx.amount}</td>
                <td>{tx.created_at ? new Date(tx.created_at).toLocaleString() : '-'}</td>
              </tr>
            ))
          )}
        </tbody>
      </Table>

      <Modal show={showModal} onHide={() => setShowModal(false)}>
        <Modal.Header closeButton>
          <Modal.Title>Создать транзакцию</Modal.Title>
        </Modal.Header>
        <Form onSubmit={handleSubmit}>
          <Modal.Body>
            <Form.Group className="mb-3">
              <Form.Label>Карта</Form.Label>
              <Form.Select
                value={formData.card_id}
                onChange={(e) => setFormData({ ...formData, card_id: e.target.value })}
                required
              >
                <option value="">Выберите карту</option>
                {cards.filter(c => !c.blocked).map(c => (
                  <option key={c.id} value={c.id}>{c.number} ({c.balance} руб., {c.owner_name})</option>
                ))}
              </Form.Select>
            </Form.Group>
            <Form.Group className="mb-3">
              <Form.Label>Терминал</Form.Label>
              <Form.Select
                value={formData.terminal_id}
                onChange={(e) => setFormData({ ...formData, terminal_id: e.target.value })}
                required
              >
                <option value="">Выберите терминал</option>
                {terminals.map(t => (
                  <option key={t.id} value={t.id}>{t.name}</option>
                ))}
              </Form.Select>
            </Form.Group>
            <Form.Group className="mb-3">
              <Form.Label>Сумма</Form.Label>
              <Form.Control
                type="number"
                value={formData.amount}
                onChange={(e) => setFormData({ ...formData, amount: e.target.value })}
                required
              />
            </Form.Group>
          </Modal.Body>
          <Modal.Footer>
            <Button variant="secondary" onClick={() => setShowModal(false)}>Отмена</Button>
            <Button variant="primary" type="submit" disabled={loading}>
              {loading ? 'Создание...' : 'Создать'}
            </Button>
          </Modal.Footer>
        </Form>
      </Modal>
    </div>
  );
}

export default Transactions;