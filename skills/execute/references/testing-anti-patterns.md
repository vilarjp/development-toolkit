# Testing Anti-Patterns

Patterns that make tests unreliable, brittle, or worthless. Recognize these and stop. Each anti-pattern includes the bad way, the good way, and why it matters.

---

## 1. Mocking the Thing Under Test

**What it is:** Replacing the actual behavior of the code you are testing with a mock, so the test verifies the mock instead of the real code.

**Why it is bad:** The test passes regardless of whether the real code works. You are testing your test setup, not your application.

**Bad:**
```typescript
// Testing that UserService.create works, but mocking UserService itself
const mockCreate = jest.fn().mockResolvedValue({ id: 1, name: "Alice" });
const service = { create: mockCreate };

test("creates a user", async () => {
  const result = await service.create({ name: "Alice" });
  expect(result).toEqual({ id: 1, name: "Alice" }); // Always passes
});
```

**Good:**
```typescript
// Testing UserService.create with a real instance, mocking only the external dependency
const mockDatabase = new InMemoryDatabase();
const service = new UserService(mockDatabase);

test("creates a user", async () => {
  const result = await service.create({ name: "Alice" });
  expect(result.id).toBeDefined();
  expect(result.name).toBe("Alice");
  expect(await mockDatabase.findById(result.id)).toEqual(result);
});
```

**Rule:** Mock dependencies at boundaries (databases, APIs, file system). Never mock the thing you are testing.

---

## 2. Testing Private/Internal Methods

**What it is:** Writing tests that directly call private methods, internal functions, or implementation details that are not part of the public API.

**Why it is bad:** These tests break when you refactor internals, even if the behavior is unchanged. They couple your tests to your implementation instead of your contract.

**Bad:**
```python
# Directly testing a private method
class PriceCalculator:
    def _apply_discount(self, price, discount_pct):
        return price * (1 - discount_pct / 100)

    def calculate(self, items, discount_pct):
        total = sum(item.price for item in items)
        return self._apply_discount(total, discount_pct)

def test_apply_discount():
    calc = PriceCalculator()
    # Calling a private method directly -- will break if method is renamed or inlined
    assert calc._apply_discount(100, 10) == 90.0
```

**Good:**
```python
# Testing through the public interface
def test_calculate_with_discount():
    calc = PriceCalculator()
    items = [Item(price=60), Item(price=40)]
    result = calc.calculate(items, discount_pct=10)
    assert result == 90.0

def test_calculate_without_discount():
    calc = PriceCalculator()
    items = [Item(price=60), Item(price=40)]
    result = calc.calculate(items, discount_pct=0)
    assert result == 100.0
```

**Rule:** Test the public interface. If you feel the need to test a private method, it may deserve to be extracted into its own class with its own public API.

---

## 3. Snapshot Testing Without Understanding

**What it is:** Generating a snapshot of output (HTML, JSON, objects), committing it without reading it, and asserting that future output matches exactly.

**Why it is bad:** The snapshot becomes a change detector, not a correctness check. When it breaks, developers update the snapshot without understanding what changed. Real bugs get accepted as "just a snapshot update."

**Bad:**
```javascript
// Blindly snapshot a component -- any change triggers a failure
test("renders user profile", () => {
  const tree = renderer.create(<UserProfile user={mockUser} />).toJSON();
  expect(tree).toMatchSnapshot();
  // 200+ lines of HTML captured, nobody reads them
});
```

**Good:**
```javascript
// Test specific behaviors, not the entire output
test("renders user name and email", () => {
  render(<UserProfile user={mockUser} />);
  expect(screen.getByText("Alice Johnson")).toBeInTheDocument();
  expect(screen.getByText("alice@example.com")).toBeInTheDocument();
});

test("renders edit button for own profile", () => {
  render(<UserProfile user={mockUser} isOwnProfile={true} />);
  expect(screen.getByRole("button", { name: "Edit Profile" })).toBeInTheDocument();
});

test("hides edit button for other profiles", () => {
  render(<UserProfile user={mockUser} isOwnProfile={false} />);
  expect(screen.queryByRole("button", { name: "Edit Profile" })).not.toBeInTheDocument();
});
```

**Rule:** If you use snapshots, keep them small and read every line. Prefer explicit assertions for behavior over snapshots for structure.

---

## 4. Tests That Depend on Execution Order

**What it is:** Test A creates state that Test B depends on. If Test A runs first, B passes. If they run in a different order, B fails.

**Why it is bad:** Tests become flaky. Running a single test in isolation fails. Parallelization breaks everything. Debugging becomes a nightmare because the bug is not in the code but in test ordering.

**Bad:**
```python
# test_user.py -- Test B depends on Test A's side effect
class TestUserWorkflow:
    def test_create_user(self):
        # Creates a user in a shared database
        response = client.post("/users", json={"name": "Alice"})
        assert response.status_code == 201

    def test_get_user(self):
        # Assumes test_create_user ran first and the user exists
        response = client.get("/users/1")
        assert response.status_code == 200
        assert response.json()["name"] == "Alice"
```

**Good:**
```python
# Each test creates its own state
class TestUserWorkflow:
    def test_create_user(self):
        response = client.post("/users", json={"name": "Alice"})
        assert response.status_code == 201

    def test_get_user(self):
        # Set up its own precondition
        client.post("/users", json={"name": "Bob"})
        response = client.get("/users/1")
        assert response.status_code == 200
        assert response.json()["name"] == "Bob"
```

**Rule:** Each test must set up its own state and clean up after itself. Use `beforeEach`/`setUp` to reset state. Never rely on test execution order.

---

## 5. Testing Implementation Details Instead of Behavior

**What it is:** Writing tests that verify HOW something is done (which functions are called, in what order, with what arguments) instead of WHAT the outcome is.

**Why it is bad:** Any refactoring breaks the tests even when the behavior is correct. The tests become a mirror of the implementation, adding maintenance burden with no safety benefit.

**Bad:**
```typescript
// Testing that specific internal methods are called in a specific order
test("processes order", () => {
  const spy1 = jest.spyOn(service, "validateOrder");
  const spy2 = jest.spyOn(service, "calculateTotal");
  const spy3 = jest.spyOn(service, "applyDiscount");
  const spy4 = jest.spyOn(service, "saveOrder");

  service.processOrder(order);

  expect(spy1).toHaveBeenCalledBefore(spy2);
  expect(spy2).toHaveBeenCalledBefore(spy3);
  expect(spy3).toHaveBeenCalledBefore(spy4);
  expect(spy4).toHaveBeenCalledWith(expect.objectContaining({ total: 90 }));
});
```

**Good:**
```typescript
// Testing the observable outcome
test("processes order with 10% discount", () => {
  const order = createOrder({ items: [{ price: 50 }, { price: 50 }], discountCode: "SAVE10" });
  const result = service.processOrder(order);

  expect(result.total).toBe(90);
  expect(result.status).toBe("confirmed");
  expect(result.items).toHaveLength(2);
});

test("rejects order with invalid items", () => {
  const order = createOrder({ items: [] });
  expect(() => service.processOrder(order)).toThrow("Order must have at least one item");
});
```

**Rule:** Test inputs and outputs. Test that given X, the result is Y. Do not test that function A calls function B -- that is an implementation detail that may change.

---

## 6. Weak Assertions

**What it is:** Assertions that pass for almost any result instead of checking for the specific expected value.

**Why it is bad:** The test can pass with wrong results. If the function returns the wrong value but it happens to be non-null or non-empty, the test still passes. You have a false sense of safety.

**Bad:**
```python
def test_calculate_total():
    result = calculate_total([10, 20, 30])
    assert result is not None       # Passes if result is 0, -1, "error", anything
    assert result > 0               # Passes if result is 1 or 999999
    assert isinstance(result, int)  # Passes if result is 42 instead of 60

def test_get_users():
    users = get_users()
    assert len(users) > 0           # Passes with 1 user or 1000 users
    assert users                    # Same as above -- just checks truthiness
```

**Good:**
```python
def test_calculate_total():
    result = calculate_total([10, 20, 30])
    assert result == 60

def test_get_users_returns_all_seeded_users():
    seed_users(["Alice", "Bob", "Charlie"])
    users = get_users()
    assert len(users) == 3
    assert [u.name for u in users] == ["Alice", "Bob", "Charlie"]
```

**Rule:** Assert the exact expected value. `assertEqual(actual, expected)` not `assertTrue(actual != None)`. If you cannot state the expected value, you do not understand what you are testing.

---

## 7. Tests That Always Pass

**What it is:** A test that passes regardless of what the code does. Usually caused by missing assertions, wrong setup, or tautological checks.

**Why it is bad:** The test provides zero safety. It exists in the test count, giving false confidence. The behavior it claims to test is actually untested.

**Bad:**
```typescript
// No assertion at all
test("creates a user", async () => {
  const user = await createUser({ name: "Alice" });
  // ...and that's it. No expect(). The test always passes.
});

// Assertion on the mock, not the result
test("sends email", async () => {
  const mockSend = jest.fn();
  // Forgot to inject the mock into the service
  await service.sendWelcomeEmail("alice@example.com");
  expect(mockSend).not.toHaveBeenCalled(); // Always true because mock is disconnected
});

// Tautological assertion
test("returns data", () => {
  const data = { name: "Alice" };
  expect(data).toEqual(data); // Comparing a value to itself -- always true
});
```

**Good:**
```typescript
// Clear assertion on the result
test("creates a user with correct fields", async () => {
  const user = await createUser({ name: "Alice" });
  expect(user.id).toBeDefined();
  expect(user.name).toBe("Alice");
  expect(user.createdAt).toBeInstanceOf(Date);
});

// Verify the test fails first (RED phase catches this)
test("sends welcome email after registration", async () => {
  const mockEmailService = new MockEmailService();
  const service = new RegistrationService(mockEmailService);
  await service.register({ email: "alice@example.com", name: "Alice" });
  expect(mockEmailService.sentEmails).toHaveLength(1);
  expect(mockEmailService.sentEmails[0].to).toBe("alice@example.com");
  expect(mockEmailService.sentEmails[0].template).toBe("welcome");
});
```

**Rule:** Every test must have at least one meaningful assertion. The RED phase of TDD catches this -- if your test passes before you write the code, the test is wrong.

---

## 8. Testing the Framework, Not the Code

**What it is:** Writing tests that verify the behavior of the framework, library, or language runtime instead of your application code.

**Why it is bad:** You are wasting time testing code that is already tested by its maintainers. Your test does not verify your business logic. If the framework breaks, your application tests are not the right place to catch it.

**Bad:**
```python
# Testing that Django ORM works
def test_model_save():
    user = User(name="Alice", email="alice@example.com")
    user.save()
    assert User.objects.count() == 1  # Testing Django, not your code

# Testing that React renders
def test_component_renders():
    render(<div>Hello</div>)
    expect(screen.getByText("Hello")).toBeInTheDocument()  # Testing React, not your code

# Testing that JSON serialization works
def test_json_serialization():
    data = {"key": "value"}
    result = json.dumps(data)
    assert result == '{"key": "value"}'  # Testing the json module, not your code
```

**Good:**
```python
# Testing YOUR business logic that uses Django ORM
def test_user_creation_sets_default_role():
    user = User.create(name="Alice", email="alice@example.com")
    assert user.role == "viewer"  # Testing YOUR default role logic

# Testing YOUR component's behavior
def test_user_card_shows_avatar_with_initials_when_no_photo():
    render(<UserCard user={{ name: "Alice Johnson", photo: null }} />)
    expect(screen.getByText("AJ")).toBeInTheDocument()  # Testing YOUR initial-generation logic

# Testing YOUR serialization logic
def test_order_serializes_with_formatted_total():
    order = Order(items=[Item(price=10.5), Item(price=20.3)])
    result = order.to_api_response()
    assert result["formatted_total"] == "$30.80"  # Testing YOUR formatting logic
```

**Rule:** Ask: "If I remove my code and replace it with a no-op, does this test still pass?" If yes, you are testing the framework. Test your logic, your business rules, your transformations -- not the tools that execute them.

---

## Summary Table

| Anti-Pattern | Symptom | Fix |
|---|---|---|
| Mocking the thing under test | Test passes but feature is broken | Mock dependencies at boundaries, not the subject |
| Testing private methods | Refactoring breaks tests | Test through the public API |
| Blind snapshot testing | Snapshot updates accepted without review | Use specific assertions for behavior |
| Order-dependent tests | Tests fail when run individually | Each test sets up its own state |
| Testing implementation details | Tests break on every refactor | Test inputs and outputs, not internal calls |
| Weak assertions | Bugs pass undetected | Assert exact expected values |
| Tests that always pass | False confidence in test count | RED phase catches this -- test must fail first |
| Testing the framework | Wasted effort, no safety | Test your logic, not the tools |
