package com.pennywise.dto.twin;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Getter
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class ProjectionPointDto {

    private int monthsFromNow;
    private BigDecimal netWorth;
    private BigDecimal cumulativeSavings;
}
