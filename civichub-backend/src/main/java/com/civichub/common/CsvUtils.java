package com.civichub.common;

import java.util.List;

public final class CsvUtils {

    private CsvUtils() {
    }

    public record CsvValue(Object value, boolean sanitizeFormula) {
    }

    public static String row(List<?> values) {
        return values.stream()
                .map(CsvUtils::escapeTrustedValue)
                .reduce((left, right) -> left + "," + right)
                .orElse("");
    }

    public static String row(CsvValue... values) {
        return java.util.Arrays.stream(values)
                .map(value -> escape(value.value(), value.sanitizeFormula()))
                .reduce((left, right) -> left + "," + right)
                .orElse("");
    }

    public static CsvValue text(Object value) {
        return new CsvValue(value, true);
    }

    public static CsvValue trusted(Object value) {
        return new CsvValue(value, false);
    }

    public static String escapeText(Object value) {
        return escape(value, true);
    }

    public static String escapeTrustedValue(Object value) {
        return escape(value, false);
    }

    private static String escape(Object value, boolean sanitizeFormula) {
        if (value == null) {
            return "";
        }
        String text = sanitizeFormula ? sanitizeFormula(String.valueOf(value)) : String.valueOf(value);
        if (text.contains(",") || text.contains("\"") || text.contains("\n") || text.contains("\r")) {
            return "\"" + text.replace("\"", "\"\"") + "\"";
        }
        return text;
    }

    private static String sanitizeFormula(String text) {
        int index = 0;
        while (index < text.length() && Character.isWhitespace(text.charAt(index))) {
            index++;
        }
        if (index < text.length() && isFormulaPrefix(text.charAt(index))) {
            return "'" + text;
        }
        return text;
    }

    private static boolean isFormulaPrefix(char value) {
        return value == '=' || value == '+' || value == '-' || value == '@';
    }
}
