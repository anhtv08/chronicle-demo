package com.demo.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import net.openhft.chronicle.wire.SelfDescribingMarshallable;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Order model for e-commerce demo with Lombok annotations
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Order extends SelfDescribingMarshallable {
    
    private Long orderId;
    private Long customerId;
    private String customerEmail;
    private LocalDateTime orderDate;
    private LocalDateTime shippedDate;
    private OrderStatus status;
    private BigDecimal totalAmount;
    private BigDecimal shippingCost;
    private BigDecimal taxAmount;
    private String shippingAddress;
    private String billingAddress;
    private PaymentMethod paymentMethod;
    private String trackingNumber;
    private List<OrderItem> items;
    
    /**
     * Order status enum
     */
    public enum OrderStatus {
        PENDING,
        CONFIRMED,
        PROCESSING,
        SHIPPED,
        DELIVERED,
        CANCELLED,
        REFUNDED
    }
    
    /**
     * Payment method enum
     */
    public enum PaymentMethod {
        CREDIT_CARD,
        DEBIT_CARD,
        PAYPAL,
        BANK_TRANSFER,
        CASH_ON_DELIVERY
    }
    
    /**
     * Calculate subtotal (total - shipping - tax)
     */
    public BigDecimal getSubtotal() {
        return totalAmount.subtract(shippingCost).subtract(taxAmount);
    }
    
    /**
     * Check if order is completed
     */
    public boolean isCompleted() {
        return status == OrderStatus.DELIVERED;
    }
    
    /**
     * Get item count
     */
    public int getItemCount() {
        return items != null ? items.size() : 0;
    }
}