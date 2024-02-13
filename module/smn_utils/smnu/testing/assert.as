namespace smnu::testing
{
    /**
    * Asserts that the argument is false.
    * @param assert: assertion argument
    */
    shared void AssertTrue(const bool assert)
    {
        if (!assert) Throw("AssertTrue received false!");
    }

    /**
    * Asserts that the argument is true.
    * @param assert: assertion argument
    */
    shared void AssertFalse(const bool assert)
    {
        if (assert) Throw("AssertFalse received true!");
    }

    /**
    * Asserts that the two arguments are equal.
    * @param expected: the expected value, of type T
    * @param actual: the actual value, of type T
    * @poly: shared void AssertEqual(const T expected, const T actual);
    */

    shared void AssertEqual(const bool expected, const bool actual)
    {
        if (expected != actual) Throw("AssertEqual expected '" + expected + "' and received '" + actual + "'");
    }

    shared void AssertEqual(const uint expected, const uint actual)
    {
        if (expected != actual) Throw("AssertEqual expected '" + expected + "' and received '" + actual + "'");
    }

    shared void AssertEqual(const uint64 expected, const uint64 actual)
    {
        if (expected != actual) Throw("AssertEqual expected '" + expected + "' and received '" + actual + "'");
    }

    shared void AssertEqual(const int expected, const int actual)
    {
        if (expected != actual) Throw("AssertEqual expected '" + expected + "' and received '" + actual + "'");
    }

    shared void AssertEqual(const int64 expected, const int64 actual)
    {
        if (expected != actual) Throw("AssertEqual expected '" + expected + "' and received '" + actual + "'");
    }

    /**
    * Asserts that the two arguments are not equal.
    * @param expected: the expected value, of type T
    * @param actual: the actual value, of type T
    * @poly: shared void AssertNotEqual(const T expected, const T actual);
    */

    shared void AssertNotEqual(const bool expected, const bool actual)
    {
        if (expected == actual) Throw("AssertNotEqual expected '" + expected + "' and received '" + actual + "'");
    }

    shared void AssertNotEqual(const uint expected, const uint actual)
    {
        if (expected == actual) Throw("AssertNotEqual expected '" + expected + "' and received '" + actual + "'");
    }

    shared void AssertNotEqual(const uint64 expected, const uint64 actual)
    {
        if (expected == actual) Throw("AssertNotEqual expected '" + expected + "' and received '" + actual + "'");
    }

    shared void AssertNotEqual(const int expected, const int actual)
    {
        if (expected == actual) Throw("AssertNotEqual expected '" + expected + "' and received '" + actual + "'");
    }

    shared void AssertNotEqual(const int64 expected, const int64 actual)
    {
        if (expected == actual) Throw("AssertNotEqual expected '" + expected + "' and received '" + actual + "'");
    }

    /**
    * Asserts that the argument is null.
    * @param handle: assertion argument
    */
    shared void AssertNull(const Handle@ const handle)
    {
        if (handle !is null) Throw("AssertNull did not receive null!");
    }

    /**
    * Asserts that the argument is not null.
    * @param handle: assertion argument
    */
    shared void AssertNotNull(const Handle@ const handle)
    {
        if (handle is null) Throw("AssertNotNull received null!");
    }

    /**
    * Asserts that the two arguments are identical.
    * @param expected: the expected handle
    * @param actual: the actual handle
    */
    shared void AssertIdentical(const Handle@ const expected, const Handle@ const actual)
    {
        if (expected !is actual) Throw("AssertIdentical received different Handles!");
    }

    /**
    * Asserts that the two arguments are not identical.
    * @param expected: the expected handle
    * @param actual: the actual handle
    */
    shared void AssertDifferent(const Handle@ const expected, const Handle@ const actual)
    {
        if (expected is actual) Throw("AssertDifferent received identical Handles!");
    }
}
