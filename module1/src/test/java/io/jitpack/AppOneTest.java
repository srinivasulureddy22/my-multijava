package io.jitpack;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertTrue;

public class AppOneTest {
    @Test
    public void testApp() {
        AppOne.main(new String[] {});
        assertTrue(true);
    }
}
