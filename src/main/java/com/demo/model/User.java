package com.demo.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import net.openhft.chronicle.wire.SelfDescribingMarshallable;

import java.time.LocalDateTime;

/**
 * User model demonstrating Lombok annotations with Chronicle serialization
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class User extends SelfDescribingMarshallable {
    
    private Long userId;
    private String username;
    private String email;
    private String firstName;
    private String lastName;
    private LocalDateTime createdAt;
    private LocalDateTime lastLoginAt;
    private UserStatus status;
    private Double accountBalance;
    private String phoneNumber;
    
    /**
     * User status enum
     */
    public enum UserStatus {
        ACTIVE,
        INACTIVE,
        SUSPENDED,
        PENDING_VERIFICATION
    }
    
    /**
     * Helper method to get full name
     */
    public String getFullName() {
        return firstName + " " + lastName;
    }
    
    /**
     * Check if user is active
     */
    public boolean isActive() {
        return status == UserStatus.ACTIVE;
    }
}