package com.pennywise.entity;

import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

/**
 * Expense/income categories, e.g. Food, Transport, Shopping, Rent, Investment.
 * System categories have userId == null; users may also add custom categories.
 */
@Getter
@Setter
@Entity
@Table(name = "categories")
public class Category extends BaseEntity {

    private String name;

    private String icon;

    /** expense | income */
    private String type;

    /** Null for system/default categories, set for user-created custom categories. */
    private java.util.UUID userId;

    private boolean systemDefault = true;
}
