package com.demo.model;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.DisplayName;
import static org.junit.jupiter.api.Assertions.*;

import java.time.LocalDateTime;

/**
 * Unit tests for User model demonstrating Lombok functionality
 */
class UserTest {
    
    @Test
    @DisplayName("User builder should create valid user")
    void testUserBuilder() {
        // Given
        LocalDateTime now = LocalDateTime.now();
        
        // When
        User user = User.builder()
                .userId(1L)
                .username("john_doe")
                .email("john@example.com")
                .firstName("John")
                .lastName("Doe")
                .createdAt(now)
                .lastLoginAt(now)
                .status(User.UserStatus.ACTIVE)
                .accountBalance(1000.0)
                .phoneNumber("+1234567890")
                .build();
        
        // Then
        assertNotNull(user);
        assertEquals(1L, user.getUserId());
        assertEquals("john_doe", user.getUsername());
        assertEquals("john@example.com", user.getEmail());
        assertEquals("John", user.getFirstName());
        assertEquals("Doe", user.getLastName());
        assertEquals(now, user.getCreatedAt());
        assertEquals(now, user.getLastLoginAt());
        assertEquals(User.UserStatus.ACTIVE, user.getStatus());
        assertEquals(1000.0, user.getAccountBalance());
        assertEquals("+1234567890", user.getPhoneNumber());
    }
    
    @Test
    @DisplayName("User should have working equals and hashCode")
    void testEqualsAndHashCode() {
        // Given
        User user1 = User.builder()
                .userId(1L)
                .username("john_doe")
                .email("john@example.com")
                .firstName("John")
                .lastName("Doe")
                .status(User.UserStatus.ACTIVE)
                .accountBalance(1000.0)
                .build();
        
        User user2 = User.builder()
                .userId(1L)
                .username("john_doe")
                .email("john@example.com")
                .firstName("John")
                .lastName("Doe")
                .status(User.UserStatus.ACTIVE)
                .accountBalance(1000.0)
                .build();
        
        User user3 = User.builder()
                .userId(2L)
                .username("jane_doe")
                .email("jane@example.com")
                .firstName("Jane")
                .lastName("Doe")
                .status(User.UserStatus.ACTIVE)
                .accountBalance(2000.0)
                .build();
        
        // Then
        assertEquals(user1, user2);
        assertNotEquals(user1, user3);
        assertEquals(user1.hashCode(), user2.hashCode());
        assertNotEquals(user1.hashCode(), user3.hashCode());
    }
    
    @Test
    @DisplayName("User should have working toString")
    void testToString() {
        // Given
        User user = User.builder()
                .userId(1L)
                .username("john_doe")
                .email("john@example.com")
                .firstName("John")
                .lastName("Doe")
                .status(User.UserStatus.ACTIVE)
                .accountBalance(1000.0)
                .build();
        
        // When
        String userString = user.toString();
        
        // Then
        assertNotNull(userString);
        assertTrue(userString.contains("john_doe"));
        assertTrue(userString.contains("john@example.com"));
        assertTrue(userString.contains("John"));
        assertTrue(userString.contains("Doe"));
    }
    
    @Test
    @DisplayName("getFullName should concatenate first and last name")
    void testGetFullName() {
        // Given
        User user = User.builder()
                .firstName("John")
                .lastName("Doe")
                .build();
        
        // When
        String fullName = user.getFullName();
        
        // Then
        assertEquals("John Doe", fullName);
    }
    
    @Test
    @DisplayName("isActive should return true for ACTIVE status")
    void testIsActive() {
        // Given
        User activeUser = User.builder()
                .status(User.UserStatus.ACTIVE)
                .build();
        
        User inactiveUser = User.builder()
                .status(User.UserStatus.INACTIVE)
                .build();
        
        // Then
        assertTrue(activeUser.isActive());
        assertFalse(inactiveUser.isActive());
    }
    
    @Test
    @DisplayName("User should support Chronicle serialization")
    void testChronicleSerializationCompatibility() {
        // Given
        User user = User.builder()
                .userId(1L)
                .username("john_doe")
                .email("john@example.com")
                .firstName("John")
                .lastName("Doe")
                .status(User.UserStatus.ACTIVE)
                .accountBalance(1000.0)
                .build();
        
        // Then - should not throw exception when creating string representation
        // This tests that the SelfDescribingMarshallable inheritance works
        assertDoesNotThrow(() -> user.toString());
        assertNotNull(user.toString());
    }
}