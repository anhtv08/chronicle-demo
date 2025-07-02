package com.demo.util;

import com.demo.model.*;
import lombok.experimental.UtilityClass;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.concurrent.ThreadLocalRandom;

/**
 * Utility class for generating test data with realistic values
 */
@UtilityClass
public class DataGenerator {
    
    private static final String[] FIRST_NAMES = {
        "James", "Mary", "John", "Patricia", "Robert", "Jennifer", "Michael", "Linda",
        "William", "Elizabeth", "David", "Barbara", "Richard", "Susan", "Joseph", "Jessica"
    };
    
    private static final String[] LAST_NAMES = {
        "Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis",
        "Rodriguez", "Martinez", "Hernandez", "Lopez", "Gonzalez", "Wilson", "Anderson", "Thomas"
    };
    
    private static final String[] SYMBOLS = {
        "AAPL", "GOOGL", "MSFT", "AMZN", "TSLA", "META", "NVDA", "NFLX", "AMD", "INTC",
        "ORCL", "CRM", "ADBE", "PYPL", "UBER", "LYFT", "TWTR", "SNAP", "SPOT", "SQ"
    };
    
    private static final String[] EXCHANGES = {
        "NYSE", "NASDAQ", "BATS", "ARCA", "IEX"
    };
    
    /**
     * Generate a random User
     */
    public static User generateUser(Long userId) {
        ThreadLocalRandom random = ThreadLocalRandom.current();
        
        String firstName = FIRST_NAMES[random.nextInt(FIRST_NAMES.length)];
        String lastName = LAST_NAMES[random.nextInt(LAST_NAMES.length)];
        String username = (firstName + lastName + userId).toLowerCase();
        String email = username + "@example.com";
        
        return User.builder()
                .userId(userId)
                .username(username)
                .email(email)
                .firstName(firstName)
                .lastName(lastName)
                .createdAt(LocalDateTime.now().minusDays(random.nextInt(365)))
                .lastLoginAt(LocalDateTime.now().minusHours(random.nextInt(24)))
                .status(User.UserStatus.values()[random.nextInt(User.UserStatus.values().length)])
                .accountBalance(random.nextDouble(1000, 100000))
                .phoneNumber("+1" + String.format("%010d", random.nextLong(1000000000L, 9999999999L)))
                .build();
    }
    
    /**
     * Generate random MarketData
     */
    public static MarketData generateMarketData(String symbol) {
        ThreadLocalRandom random = ThreadLocalRandom.current();
        
        BigDecimal basePrice = BigDecimal.valueOf(random.nextDouble(10, 1000));
        BigDecimal spread = BigDecimal.valueOf(random.nextDouble(0.01, 0.50));
        
        BigDecimal bidPrice = basePrice.subtract(spread.divide(BigDecimal.valueOf(2)));
        BigDecimal askPrice = basePrice.add(spread.divide(BigDecimal.valueOf(2)));
        
        return MarketData.builder()
                .symbol(symbol)
                .timestamp(LocalDateTime.now())
                .bidPrice(bidPrice)
                .askPrice(askPrice)
                .lastPrice(basePrice)
                .bidSize(random.nextLong(100, 10000))
                .askSize(random.nextLong(100, 10000))
                .volume(random.nextLong(1000, 1000000))
                .high(basePrice.add(BigDecimal.valueOf(random.nextDouble(0, 10))))
                .low(basePrice.subtract(BigDecimal.valueOf(random.nextDouble(0, 10))))
                .open(basePrice.add(BigDecimal.valueOf(random.nextDouble(-5, 5))))
                .close(basePrice.add(BigDecimal.valueOf(random.nextDouble(-5, 5))))
                .exchange(EXCHANGES[random.nextInt(EXCHANGES.length)])
                .level(random.nextInt(1, 6))
                .build();
    }
    
    /**
     * Generate random Trade
     */
    public static Trade generateTrade(Long tradeId, String symbol) {
        ThreadLocalRandom random = ThreadLocalRandom.current();
        
        return Trade.builder()
                .tradeId(tradeId)
                .symbol(symbol)
                .timestamp(LocalDateTime.now())
                .price(BigDecimal.valueOf(random.nextDouble(10, 1000)))
                .quantity(random.nextLong(100, 10000))
                .side(random.nextBoolean() ? Trade.Side.BUY : Trade.Side.SELL)
                .buyOrderId("BO" + random.nextLong(100000, 999999))
                .sellOrderId("SO" + random.nextLong(100000, 999999))
                .buyClientId("CLIENT" + random.nextInt(1, 1000))
                .sellClientId("CLIENT" + random.nextInt(1, 1000))
                .exchange(EXCHANGES[random.nextInt(EXCHANGES.length)])
                .commission(BigDecimal.valueOf(random.nextDouble(0.01, 10.0)))
                .tradeType(Trade.TradeType.values()[random.nextInt(Trade.TradeType.values().length)])
                .build();
    }
    
    /**
     * Generate random Order
     */
    public static Order generateOrder(Long orderId) {
        ThreadLocalRandom random = ThreadLocalRandom.current();
        
        return Order.builder()
                .orderId(orderId)
                .customerId(random.nextLong(1, 10000))
                .customerEmail("customer" + orderId + "@example.com")
                .orderDate(LocalDateTime.now().minusDays(random.nextInt(30)))
                .shippedDate(random.nextBoolean() ? 
                    LocalDateTime.now().minusDays(random.nextInt(7)) : null)
                .status(Order.OrderStatus.values()[random.nextInt(Order.OrderStatus.values().length)])
                .totalAmount(BigDecimal.valueOf(random.nextDouble(10, 1000)))
                .shippingCost(BigDecimal.valueOf(random.nextDouble(5, 25)))
                .taxAmount(BigDecimal.valueOf(random.nextDouble(1, 50)))
                .shippingAddress(generateAddress())
                .billingAddress(generateAddress())
                .paymentMethod(Order.PaymentMethod.values()[random.nextInt(Order.PaymentMethod.values().length)])
                .trackingNumber("TRK" + random.nextLong(100000000L, 999999999L))
                .build();
    }
    
    /**
     * Generate random OrderItem
     */
    public static OrderItem generateOrderItem(Long itemId) {
        ThreadLocalRandom random = ThreadLocalRandom.current();
        
        return OrderItem.builder()
                .itemId(itemId)
                .productId(random.nextLong(1, 100000))
                .productName("Product " + itemId)
                .productSku("SKU" + String.format("%08d", itemId))
                .quantity(random.nextInt(1, 10))
                .unitPrice(BigDecimal.valueOf(random.nextDouble(5, 500)))
                .discount(random.nextBoolean() ? 
                    BigDecimal.valueOf(random.nextDouble(0, 50)) : BigDecimal.ZERO)
                .category("Category" + random.nextInt(1, 20))
                .weight(random.nextDouble(0.1, 5.0))
                .build();
    }
    
    /**
     * Generate random address
     */
    private static String generateAddress() {
        ThreadLocalRandom random = ThreadLocalRandom.current();
        return random.nextInt(100, 9999) + " Main St, City " + random.nextInt(1, 100) + 
               ", State " + random.nextInt(1, 50) + " " + String.format("%05d", random.nextInt(10000, 99999));
    }
    
    /**
     * Get random symbol from predefined list
     */
    public static String getRandomSymbol() {
        return SYMBOLS[ThreadLocalRandom.current().nextInt(SYMBOLS.length)];
    }
    
    /**
     * Get random exchange from predefined list
     */
    public static String getRandomExchange() {
        return EXCHANGES[ThreadLocalRandom.current().nextInt(EXCHANGES.length)];
    }
}