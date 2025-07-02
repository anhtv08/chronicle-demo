package com.demo.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import net.openhft.chronicle.wire.SelfDescribingMarshallable;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Market data model for financial demo with ultra-low latency requirements
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MarketData extends SelfDescribingMarshallable {
    
    private String symbol;
    private LocalDateTime timestamp;
    private BigDecimal bidPrice;
    private BigDecimal askPrice;
    private BigDecimal lastPrice;
    private Long bidSize;
    private Long askSize;
    private Long volume;
    private BigDecimal high;
    private BigDecimal low;
    private BigDecimal open;
    private BigDecimal close;
    private String exchange;
    private Integer level;
    
    /**
     * Calculate bid-ask spread
     */
    public BigDecimal getSpread() {
        return askPrice.subtract(bidPrice);
    }
    
    /**
     * Calculate mid price
     */
    public BigDecimal getMidPrice() {
        return bidPrice.add(askPrice).divide(BigDecimal.valueOf(2));
    }
    
    /**
     * Check if market is crossed (bid > ask)
     */
    public boolean isCrossed() {
        return bidPrice.compareTo(askPrice) > 0;
    }
    
    /**
     * Get price change from open
     */
    public BigDecimal getPriceChange() {
        return lastPrice.subtract(open);
    }
    
    /**
     * Get price change percentage
     */
    public BigDecimal getPriceChangePercent() {
        if (open.equals(BigDecimal.ZERO)) {
            return BigDecimal.ZERO;
        }
        return getPriceChange().divide(open, 4, BigDecimal.ROUND_HALF_UP)
                .multiply(BigDecimal.valueOf(100));
    }
}