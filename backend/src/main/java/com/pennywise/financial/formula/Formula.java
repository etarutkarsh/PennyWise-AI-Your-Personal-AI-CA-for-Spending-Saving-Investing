package com.pennywise.financial.formula;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Documents a financial formula applied in an engine method.
 * All annotated methods are discoverable via /financial/formula-registry.
 */
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
public @interface Formula {
    String name();
    String purpose();
    String expression();   // e.g. "PMT = FV × r / [(1+r)^n - 1]"
    String[] variables();  // e.g. {"FV = future value", "r = monthly rate", "n = months"}
    String reference();    // e.g. "CFP Board, SEBI"
    String[] assumptions();
    String[] limitations();
    String version() default "1.0";
}
