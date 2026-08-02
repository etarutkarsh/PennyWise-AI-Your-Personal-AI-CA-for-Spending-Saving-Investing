package com.pennywise.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TradeoffDto {

    public enum TradeoffType { PRO, CON }

    private TradeoffType type;
    private String description;

    public static TradeoffDto pro(String description) {
        return new TradeoffDto(TradeoffType.PRO, description);
    }

    public static TradeoffDto con(String description) {
        return new TradeoffDto(TradeoffType.CON, description);
    }
}
