package com.demo.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import net.openhft.chronicle.wire.SelfDescribingMarshallable;

import java.math.BigDecimal;

/**
 * Order item model with Lombok annotations
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OrderItem extends SelfDescribingMarshallable {
    
    private Long itemId;
    private Long productId;
    private String productName;
    private String productSku;
    private Integer quantity;
    private BigDecimal unitPrice;
    private BigDecimal discount;
    private String category;
    private Double weight;
    
    /**
     * Calculate total price for this item (quantity * unitPrice - discount)
     */
    public BigDecimal getTotalPrice() {
        BigDecimal total = unitPrice.multiply(BigDecimal.valueOf(quantity));
        return total.subtract(discount != null ? discount : BigDecimal.ZERO);
    }
    
    /**
     * Calculate total weight for this item
     */
    public Double getTotalWeight() {
        return weight != null ? weight * quantity : 0.0;
    }
}