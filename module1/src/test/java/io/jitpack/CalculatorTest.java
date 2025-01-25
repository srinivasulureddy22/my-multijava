package io.jitpack;

import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;

public class CalculatorTest {

    @Test
    public void testAdd() {
        Assertions.assertEquals(4, new Calculator(1, 2).add());
    }
}
