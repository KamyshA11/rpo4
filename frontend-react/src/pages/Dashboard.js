import React, { useState, useEffect } from 'react';
import { Row, Col, Card, Table, Alert, Form, Button } from 'react-bootstrap';
import { cardsApi, terminalsApi, transactionsApi } from '../services/api';

function Dashboard() {
  const [stats, setStats] = useState({ cards: 0, terminals: 0, transactions: 0 });
  const [recentTransactions, setRecentTransactions] = useState([]);
  const [terminals, setTerminals] = useState([]);
  const [error, setError] = useState('');
  const [authorizeData, setAuthorizeData] = useState({ cardNumber: '', amount: '', terminalId: '' });
  const [authorizeResult, setAuthorizeResult] = useState(null);

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      let cardsData, terminalsData, transactionsData;
      
      const cardsRes = await cardsApi.list();
      cardsData = Array.isArray(cardsRes) ? cardsRes : (cardsRes.data || []);
      
      const terminalsRes = await terminalsApi.list();
      terminalsData = Array.isArray(terminalsRes) ? terminalsRes : (terminalsRes.data || []);
      
      const transactionsRes = await transactionsApi.list();
      transactionsData = Array.isArray(transactionsRes) ? transactionsRes : (transactionsRes.data || []);
      
      setStats({
        cards: cardsData.length || 0,
        terminals: terminalsData.length || 0,
        transactions: transactionsData.length || 0,
      });
      setRecentTransactions(transactionsData.slice(-5).reverse());
      setTerminals(terminalsData);
    } catch (err) {
      setError(err.message);
    }
  };

  const handleAuthorize = async (e) => {
    e.preventDefault();
    setAuthorizeResult(null);
    try {
      const result = await terminalsApi.authorize(
        authorizeData.cardNumber,
        parseFloat(authorizeData.amount),
        parseInt(authorizeData.terminalId)
      );
      setAuthorizeResult({ success: true, message: result.message || 'Авторизация успешна' });
      loadData();
    } catch (err) {
      setAuthorizeResult({ success: false, message: err.message });
    }
  };

  return (
    <div>
      <h2 className="mb-4">Дашборд</h2>
      
      {error && <Alert variant="danger" className="mb-4">{error}</Alert>}

      <Row className="mb-4">
        <Col md={4}>
          <Card className="stats-card">
            <Card.Body>
              <div className="stats-number">{stats.cards}</div>
              <div>Карт</div>
            </Card.Body>
          </Card>
        </Col>
        <Col md={4}>
          <Card className="stats-card">
            <Card.Body>
              <div className="stats-number">{stats.terminals}</div>
              <div>Терминалов</div>
            </Card.Body>
          </Card>
        </Col>
        <Col md={4}>
          <Card className="stats-card">
            <Card.Body>
              <div className="stats-number">{stats.transactions}</div>
              <div>Транзакций</div>
            </Card.Body>
          </Card>
        </Col>
      </Row>

      <Row>
        <Col md={6} className="mb-4">
          <Card>
            <Card.Header>Быстрая авторизация платежа</Card.Header>
            <Card.Body>
              <Form onSubmit={handleAuthorize}>
                <Form.Group className="mb-3">
                  <Form.Label>Номер карты</Form.Label>
                  <Form.Control
                    type="text"
                    value={authorizeData.cardNumber}
                    onChange={(e) => setAuthorizeData({ ...authorizeData, cardNumber: e.target.value })}
                    required
                  />
                </Form.Group>
                <Form.Group className="mb-3">
                  <Form.Label>Сумма</Form.Label>
                  <Form.Control
                    type="number"
                    value={authorizeData.amount}
                    onChange={(e) => setAuthorizeData({ ...authorizeData, amount: e.target.value })}
                    required
                  />
                </Form.Group>
                <Form.Group className="mb-3">
                  <Form.Label>Терминал</Form.Label>
                  <Form.Select
                    value={authorizeData.terminalId}
                    onChange={(e) => setAuthorizeData({ ...authorizeData, terminalId: e.target.value })}
                    required
                  >
                    <option value="">Выберите терминал</option>
                    {terminals.map(t => (
                      <option key={t.id} value={t.id}>{t.name || t.serial || t.id}</option>
                    ))}
                  </Form.Select>
                </Form.Group>
                <Button variant="primary" type="submit">Авторизовать</Button>
              </Form>
              {authorizeResult && (
                <Alert variant={authorizeResult.success ? 'success' : 'danger'} className="mt-3">
                  {authorizeResult.message}
                </Alert>
              )}
            </Card.Body>
          </Card>
        </Col>

        <Col md={6} className="mb-4">
          <Card>
            <Card.Header>Последние транзакции</Card.Header>
            <Card.Body>
              {recentTransactions.length === 0 ? (
                <p className="text-muted">Нет транзакций</p>
              ) : (
                <Table responsive>
                  <thead>
                    <tr>
                      <th>ID</th>
                      <th>Карта</th>
                      <th>Терминал</th>
                      <th>Сумма</th>
                    </tr>
                  </thead>
                  <tbody>
                    {recentTransactions.map(tx => (
                      <tr key={tx.id}>
                        <td>{tx.id}</td>
                        <td>{tx.card_id}</td>
                        <td>{tx.terminal_id}</td>
                        <td>{tx.amount}</td>
                      </tr>
                    ))}
                  </tbody>
                </Table>
              )}
            </Card.Body>
          </Card>
        </Col>
      </Row>
    </div>
  );
}

export default Dashboard;