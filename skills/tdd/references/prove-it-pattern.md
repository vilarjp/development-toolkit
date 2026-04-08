# The Prove-It Pattern

A structured approach for fixing bugs through test-driven development. The bug report becomes the test specification. The test proves the bug exists, the fix works, and the bug cannot return.

---

## Step 1: Understand the Bug

Before writing any code or any test, understand what is actually happening.

**Read the bug report.** Extract these facts:
- **Expected behavior:** What should happen
- **Actual behavior:** What happens instead
- **Reproduction steps:** How to trigger the bug
- **Environment:** Where it occurs (browser, OS, API version, data state)
- **Frequency:** Always, sometimes, only under specific conditions

**If the bug report is vague,** fill in the gaps:
- Read the relevant source code to understand the intended behavior
- Check git blame to see when the behavior was introduced
- Check if there are existing tests that should have caught this (if so, why did they not?)

**Reproduce manually if possible.** Run the application, follow the reproduction steps, observe the failure. This confirms the bug is real and gives you a concrete understanding of what "fixed" looks like.

Do NOT start writing code until you can describe the bug in a single sentence:
```
"When [precondition], doing [action] produces [actual result] instead of [expected result]."
```

Examples:
- "When a user has zero items in their cart, clicking checkout produces a 500 error instead of showing the empty cart message."
- "When the API receives a request with a date in ISO format, parsing fails with a timezone error instead of returning the correct UTC timestamp."
- "When two concurrent requests update the same record, the second request silently overwrites the first instead of returning a 409 conflict."

---

## Step 2: Write the Reproduction Test

The reproduction test must:
1. Set up the precondition described in the bug
2. Perform the action that triggers the bug
3. Assert the EXPECTED behavior (not the buggy behavior)

The test MUST FAIL with the current code. If it passes, one of these is wrong:
- Your understanding of the bug
- Your test setup (precondition not matching the real scenario)
- Your assertion (testing the wrong thing)
- The bug has already been fixed

**Structure of a reproduction test:**

```
test("[bug-id] [description of expected behavior]", () => {
  // ARRANGE: Set up the precondition that triggers the bug
  // ACT: Perform the action
  // ASSERT: Verify the expected (correct) behavior
});
```

**Example -- Empty cart bug:**

```typescript
test("BUG-123: checkout with empty cart shows empty cart message", async () => {
  // Arrange: user with empty cart
  const user = await createUser();
  // No items added to cart

  // Act: attempt checkout
  const response = await checkout(user.id);

  // Assert: should show empty cart message, not crash
  expect(response.status).toBe(200);
  expect(response.body.message).toBe("Your cart is empty");
});
```

This test will FAIL with a 500 error (the bug). That failure proves the bug exists in the test suite.

**Example -- Timezone parsing bug:**

```python
def test_bug_456_iso_date_with_timezone_parses_correctly():
    """When API receives ISO date with timezone, it should parse to correct UTC."""
    # Arrange
    request_body = {"date": "2024-03-15T10:30:00+05:30"}

    # Act
    result = parse_request_date(request_body)

    # Assert: should be converted to UTC correctly
    assert result == datetime(2024, 3, 15, 5, 0, 0, tzinfo=timezone.utc)
```

This test will FAIL with a timezone parsing error (the bug).

**Example -- Race condition bug:**

```python
def test_bug_789_concurrent_updates_return_conflict():
    """When two requests update the same record, the second should return 409."""
    # Arrange
    record = create_record({"value": "original"})

    # Act: simulate concurrent updates
    response_1 = update_record(record.id, {"value": "update_1"}, version=record.version)
    response_2 = update_record(record.id, {"value": "update_2"}, version=record.version)

    # Assert
    assert response_1.status == 200
    assert response_2.status == 409  # Should conflict, not silently overwrite
```

---

## Step 3: Confirm the Test Fails Correctly

Run the test. It must fail. But it must fail for the RIGHT reason.

**Right reason:** The assertion fails because the code exhibits the buggy behavior.
- `Expected 200 but got 500` (the bug is a crash)
- `Expected "Your cart is empty" but got undefined` (the bug is a missing message)
- `Expected 409 but got 200` (the bug is a missing conflict check)

**Wrong reasons (fix the test, not the code):**
- `TypeError: cannot read property 'id' of undefined` -- Your test setup is wrong. The precondition is not set up correctly.
- `ConnectionRefusedError` -- The test environment is not configured. Fix the environment.
- `ModuleNotFoundError` -- A dependency is missing. Install it.
- The test passes -- Your understanding of the bug is wrong, or the bug is not reproducible in this context. Investigate further.

If the test fails for the wrong reason, fix the test until it fails for the right reason. The failure message should clearly describe the bug.

---

## Step 4: Implement the Minimal Fix

Now write the fix. Rules:

1. **Minimum change.** Fix the bug and nothing else. Do not refactor adjacent code. Do not add features. Do not "improve" the area while you are there. The fix should be as small as possible.

2. **Stay in scope.** If fixing the bug reveals other bugs, file them separately. Do not fix them in this change. One bug, one fix, one test.

3. **Do not change the test.** The test was written before the fix. It describes the expected behavior. If you need to change the test to make it pass, your fix is wrong, or your test was wrong from the start. Decide which and act accordingly.

**Example -- Empty cart fix:**

```typescript
// BEFORE (buggy): crashes when items is empty
function processCheckout(userId: string) {
  const items = getCartItems(userId);
  const total = items.reduce((sum, item) => sum + item.price, 0);
  return chargeUser(userId, total); // crashes if items is empty: chargeUser(userId, 0) hits a validation error
}

// AFTER (fixed): handle empty cart
function processCheckout(userId: string) {
  const items = getCartItems(userId);
  if (items.length === 0) {
    return { status: 200, body: { message: "Your cart is empty" } };
  }
  const total = items.reduce((sum, item) => sum + item.price, 0);
  return chargeUser(userId, total);
}
```

The fix is a single `if` check. Nothing else changed.

---

## Step 5: Confirm the Test Passes

Run the reproduction test. It MUST now pass.

If it still fails:
- Read the failure message carefully
- Your fix did not address the actual cause
- Revert the fix and re-examine the bug

If it passes, proceed to the next step.

---

## Step 6: Run the Full Suite

Run the FULL test suite, not just the new test.

**If all tests pass:** The fix is correct and introduces no regressions. Done.

**If other tests fail:** Your fix broke something. This means either:
- The fix has an unintended side effect (fix the side effect, keep the bug fix)
- Other tests depended on the buggy behavior (update those tests -- they were testing the wrong thing)
- The fix is too broad and changed more than the bug (narrow the fix)

Do NOT delete failing tests to make the suite green. Understand why they fail. If they fail because they expected the buggy behavior, update them to expect the correct behavior. If they fail for unrelated reasons, your fix has a side effect.

---

## Step 7: Common Mistakes

### Writing a Test That Passes Without the Fix

The test asserts the actual (buggy) behavior instead of the expected (correct) behavior. This happens when you write the test after the fix -- it matches the new code instead of defining the correct behavior.

**Prevention:** Write the test BEFORE the fix. Run it. Watch it fail. Then fix.

### Testing the Wrong Behavior

The test verifies a symptom of the bug instead of the root cause. The fix addresses the symptom, and the same bug reappears in a different form.

**Prevention:** Trace the bug to its root cause before writing the test. Test the root cause, not the symptom.

**Example:**
- Bug: "Login fails with special characters in password"
- Symptom-level test: `test that login with @ in password works` (narrow, fragile)
- Root-cause test: `test that password is properly encoded before transmission` (covers all special characters)

### Fixing More Than the Bug

While fixing the bug, you notice the surrounding code is messy. You refactor it. You add error handling for other cases. You rename variables for clarity. Now the diff is 200 lines instead of 5, and the code review cannot distinguish the bug fix from the cleanup.

**Prevention:** Fix the bug. Only the bug. File a separate task for the cleanup. The bug fix diff should be as small as possible.

### Not Running the Full Suite

You run only the new test. It passes. You declare victory. Meanwhile, your fix broke three other features that you did not check.

**Prevention:** Always run the full suite after the fix. If the suite is slow, run at least the tests in the same module. But ideally, the full suite.

### Assuming the Bug Is Fixed

You write the fix, it "looks right," and you move on without running the reproduction test. The fix does not actually address the bug, and it ships.

**Prevention:** Run the reproduction test. Watch it pass. Do not assume. Prove it.
