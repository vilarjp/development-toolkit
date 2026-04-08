# Test Pyramid Reference

The test pyramid defines the ratio and purpose of different test types. It is not a rule of thumb -- it is an engineering discipline that balances speed, coverage, and confidence.

```
        /  E2E  \          5%   — Critical user flows
       / Integr. \        15%   — Component boundaries
      /   Unit    \       80%   — Pure logic, isolated
     /______________\
```

---

## Unit Tests (80%)

### What They Test
Pure logic in isolation. One function, one class, one module -- with all external dependencies mocked or stubbed. The test verifies that given specific inputs, the unit produces the correct output.

### When to Write Them
- For every piece of business logic
- For every data transformation
- For every validation rule
- For every utility function
- For every state transition
- For every conditional branch you want to verify

### How to Write Them

**Structure: Arrange → Act → Assert**

```typescript
test("calculates shipping cost for domestic orders under 5kg", () => {
  // Arrange
  const order = createOrder({
    weight: 3.5,
    destination: { country: "US", state: "CA" },
  });

  // Act
  const cost = calculateShipping(order);

  // Assert
  expect(cost).toBe(5.99);
});
```

**One behavior per test.** If a function has three branches, write three tests -- not one test with three assertions that exercise all branches.

```
// Bad: one test, three behaviors
test("calculates shipping", () => {
  expect(calculateShipping(lightDomestic)).toBe(5.99);
  expect(calculateShipping(heavyDomestic)).toBe(12.99);
  expect(calculateShipping(international)).toBe(24.99);
});

// Good: three tests, one behavior each
test("domestic order under 5kg costs $5.99", () => { ... });
test("domestic order over 5kg costs $12.99", () => { ... });
test("international order costs $24.99", () => { ... });
```

### When to Use Mocks

Mock at boundaries -- where your code meets external systems:

| Boundary | Mock Strategy |
|----------|--------------|
| Database | In-memory repository or fake |
| HTTP API | Fake server or response stub |
| File system | In-memory filesystem |
| Clock/time | Fixed clock |
| Random | Seeded generator |
| Environment variables | Injected config object |

**Do NOT mock:**
- The thing you are testing
- Pure functions (just call them)
- Value objects and data structures
- Internal helper functions

**Isolation pattern:**

```typescript
// Inject dependencies so they can be replaced in tests
class OrderService {
  constructor(
    private readonly db: OrderRepository,
    private readonly emailer: EmailService,
  ) {}

  async placeOrder(order: Order): Promise<OrderResult> {
    const saved = await this.db.save(order);
    await this.emailer.sendConfirmation(order.email, saved.id);
    return saved;
  }
}

// In tests: inject fakes
test("placeOrder saves and sends confirmation", async () => {
  const fakeDb = new InMemoryOrderRepository();
  const fakeEmailer = new FakeEmailService();
  const service = new OrderService(fakeDb, fakeEmailer);

  const result = await service.placeOrder(testOrder);

  expect(fakeDb.findById(result.id)).toBeDefined();
  expect(fakeEmailer.sentTo).toContain(testOrder.email);
});
```

### Speed Target
Each unit test should run in under 50ms. The entire unit test suite should run in seconds, not minutes. If your unit tests are slow, they are probably integration tests in disguise.

---

## Integration Tests (15%)

### What They Test
Boundaries between components. They verify that two or more units work together correctly -- that the wiring is right, the data flows through, and the contracts are honored.

### When You Need Them
- When two modules communicate over an interface (service → repository)
- When data passes through a serialization/deserialization boundary
- When your code integrates with a real database, message queue, or cache
- When API endpoints handle real HTTP requests end-to-end within the server
- When middleware, validation, and handlers work together in sequence

### How to Write Them

**API integration test:**

```typescript
describe("POST /api/users", () => {
  let app: Application;
  let db: TestDatabase;

  beforeEach(async () => {
    db = await TestDatabase.create();
    app = createApp({ database: db });
  });

  afterEach(async () => {
    await db.cleanup();
  });

  test("creates user and returns 201 with user object", async () => {
    const response = await request(app)
      .post("/api/users")
      .send({ name: "Alice", email: "alice@example.com" });

    expect(response.status).toBe(201);
    expect(response.body.name).toBe("Alice");
    expect(response.body.id).toBeDefined();

    // Verify it actually persisted
    const saved = await db.users.findById(response.body.id);
    expect(saved.email).toBe("alice@example.com");
  });

  test("returns 400 for duplicate email", async () => {
    await db.users.insert({ name: "Bob", email: "alice@example.com" });

    const response = await request(app)
      .post("/api/users")
      .send({ name: "Alice", email: "alice@example.com" });

    expect(response.status).toBe(400);
    expect(response.body.error).toBe("email_taken");
  });
});
```

**Database integration test:**

```python
class TestOrderRepository:
    def setup_method(self):
        self.db = create_test_database()
        self.repo = OrderRepository(self.db)

    def teardown_method(self):
        self.db.rollback()

    def test_save_and_retrieve_order(self):
        order = Order(customer_id=1, items=[Item(product_id=10, quantity=2)])
        saved = self.repo.save(order)

        retrieved = self.repo.find_by_id(saved.id)
        assert retrieved.customer_id == 1
        assert len(retrieved.items) == 1
        assert retrieved.items[0].quantity == 2

    def test_find_by_customer_returns_only_their_orders(self):
        self.repo.save(Order(customer_id=1, items=[Item(product_id=10, quantity=1)]))
        self.repo.save(Order(customer_id=2, items=[Item(product_id=20, quantity=1)]))

        orders = self.repo.find_by_customer(1)
        assert len(orders) == 1
        assert orders[0].customer_id == 1
```

### Testing Patterns

**Test database:** Use an in-memory database (SQLite, H2) or a test-specific instance of the real database. Roll back transactions after each test to keep tests isolated.

**Test API server:** Start the server in-process, make real HTTP requests against it, and verify responses. Shut down after the test suite.

**External API mocking:** Use a local mock server (WireMock, nock, responses) to simulate third-party APIs. Test your code's behavior when the API returns success, errors, and timeouts.

### Speed Target
Integration tests should run in seconds per test, not minutes. The full integration suite should complete in under 2 minutes. If it takes longer, you may have too many integration tests or they are doing too much work.

---

## E2E Tests (5%)

### What They Test
Critical user flows through the entire system. From the user's browser or API client through the full stack to the database and back. They verify that the whole thing works together.

### When They Are Worth It
- Login and authentication flow
- Core business transaction (checkout, payment, order placement)
- Data-critical flows (user registration, data export)
- Flows that cross multiple services or systems

### When They Are NOT Worth It
- Testing individual form fields (unit test)
- Testing API response shapes (integration test)
- Testing error message formatting (unit test)
- Testing features that have comprehensive unit and integration coverage

### How to Write Them

**Browser E2E test:**

```typescript
test("user can register and place an order", async ({ page }) => {
  // Register
  await page.goto("/register");
  await page.fill('[name="email"]', "alice@example.com");
  await page.fill('[name="password"]', "securepassword123");
  await page.click('button[type="submit"]');
  await expect(page).toHaveURL("/dashboard");

  // Add item to cart
  await page.goto("/products");
  await page.click('[data-testid="product-1"] button');
  await expect(page.locator('[data-testid="cart-count"]')).toHaveText("1");

  // Checkout
  await page.goto("/checkout");
  await page.fill('[name="card"]', "4242424242424242");
  await page.click('button:has-text("Place Order")');
  await expect(page.locator('[data-testid="confirmation"]')).toContainText("Order confirmed");
});
```

**API E2E test:**

```python
def test_complete_order_flow():
    # Register
    user = api.post("/auth/register", {"email": "test@example.com", "password": "pass123"})
    token = user["token"]

    # Browse products
    products = api.get("/products", headers={"Authorization": f"Bearer {token}"})
    product_id = products[0]["id"]

    # Add to cart
    api.post("/cart/items", {"product_id": product_id, "quantity": 1}, headers={"Authorization": f"Bearer {token}"})

    # Checkout
    order = api.post("/orders", {"payment_method": "test_card"}, headers={"Authorization": f"Bearer {token}"})
    assert order["status"] == "confirmed"
    assert order["items"][0]["product_id"] == product_id

    # Verify order appears in history
    history = api.get("/orders", headers={"Authorization": f"Bearer {token}"})
    assert len(history) == 1
    assert history[0]["id"] == order["id"]
```

### How to Keep Them Fast
- Use API shortcuts for setup (create user via API, not through the UI)
- Parallelize independent test files
- Use a fast test environment (local, not staging)
- Limit E2E tests to critical paths only -- resist the urge to add E2E tests for everything
- Clean up data between tests to avoid interference

### Speed Target
Each E2E test should run in under 30 seconds. The full E2E suite should complete in under 5 minutes. If it takes longer, you have too many E2E tests. Move some coverage down to integration or unit tests.

---

## Decision Guide

Use this flowchart when deciding which test type to write.

**Is it pure logic with no external dependencies?**
→ Yes: **Unit test.** Mock nothing. Test inputs and outputs.

**Does it cross a boundary between two components?**
→ Yes: **Integration test.** Use the real boundary (database, HTTP, message queue) in a test environment.

**Is it a critical user flow that involves the full stack?**
→ Yes: **E2E test.** Test the complete flow from the user's perspective.

**Is it a configuration or wiring concern?**
→ **Integration test.** Verify that components are wired together correctly.

**Is it a visual/layout concern?**
→ **Unit test** with snapshot or visual regression tool. Or **E2E test** with screenshot comparison if layout is critical.

**Is it an error handling path?**
→ **Unit test** for the error detection logic. **Integration test** for error propagation across boundaries.

### Quick Reference Table

| Scenario | Test Type | Reason |
|----------|-----------|--------|
| `formatCurrency(1234.5)` returns `"$1,234.50"` | Unit | Pure logic, no dependencies |
| `UserService.create` saves to database | Integration | Crosses service-database boundary |
| User registers, logs in, places order | E2E | Full user flow across the stack |
| `validateEmail("bad")` returns error | Unit | Pure validation logic |
| POST `/api/users` returns 201 with body | Integration | HTTP layer + service + database |
| Webhook handler processes Stripe event | Integration | External system boundary |
| Retry logic backs off exponentially | Unit | Pure logic with a clock mock |
| Two services communicate via message queue | Integration | Cross-service boundary |
| User uploads file and downloads it | E2E | Full flow with file storage |
| `sortByDate(items)` orders correctly | Unit | Pure transformation logic |

---

## Common Pyramid Violations

### Inverted Pyramid (Too Many E2E)
**Symptom:** Most tests are E2E. Test suite takes 20+ minutes. Tests are flaky.
**Fix:** Identify the logic being tested in E2E tests. Write unit tests for that logic. Remove the E2E test if the logic is now covered.

### Missing Middle (No Integration)
**Symptom:** Lots of unit tests, a few E2E tests, nothing in between. Bugs appear at component boundaries.
**Fix:** For each E2E test, ask: "What boundary is this really testing?" Write an integration test for that boundary. Demote the E2E test if the boundary is now covered.

### Ice Cream Cone (Manual Testing)
**Symptom:** Most testing is manual. Automated tests exist but are not trusted. Manual regression cycles take days.
**Fix:** Start at the bottom. Write unit tests for the most critical business logic. Then add integration tests for the most important boundaries. Automate the manual test scripts as E2E last.

### Diamond (Too Many Integration)
**Symptom:** The integration test suite is the largest. Slow and hard to maintain. Many tests overlap.
**Fix:** Identify pure logic being tested through integration tests. Extract it and write unit tests. Reserve integration tests for actual boundary verification.
