package com.demo.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import net.openhft.chronicle.wire.SelfDescribingMarshallable;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Trade execution model for high-frequency trading demo
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Trade extends SelfDescribingMarshallable {
    
    private Long tradeId;
    private String symbol;
    private LocalDateTime timestamp;
    private BigDecimal price;
    private Long quantity;
    private Side side;
    private String buyOrderId;
    private String sellOrderId;
    private String buyClientId;
    private String sellClientId;
    private String exchange;
    private BigDecimal commission;
    private TradeType tradeType;
    
    /**
     * Trade side enum
     */
    public enum Side {
        BUY,
        SELL
    }
    
    /**
     * Trade type enum
     */
    public enum TradeType {
        MARKET,
        LIMIT,
        STOP,
        STOP_LIMIT,
        ICEBERG
    }
    
    /**
     * Calculate notional value
     */
    public BigDecimal getNotionalValue() {
        return price.multiply(BigDecimal.valueOf(quantity));
    }
    
    /**
     * Calculate net amount (including commission)
     */
    public BigDecimal getNetAmount() {
        BigDecimal notional = getNotionalValue();
        return side == Side.BUY ? 
            notional.add(commission) : 
            notional.subtract(commission);
    }
}