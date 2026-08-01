package com.pennywise.dto.auth;

public class OtpSendResponse {

    private final String message;
    /** Only populated in dev mode (no SMS provider configured). Null in production. */
    private final String devOtp;

    public OtpSendResponse(String message, String devOtp) {
        this.message = message;
        this.devOtp = devOtp;
    }

    public String getMessage() { return message; }
    public String getDevOtp() { return devOtp; }
}
