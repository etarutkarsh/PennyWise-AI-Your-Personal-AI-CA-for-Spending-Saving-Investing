package com.pennywise.controller;

import com.pennywise.dto.UserDto;
import com.pennywise.dto.UserUpdateRequest;
import com.pennywise.service.UserService;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/users")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping("/me")
    public UserDto getMe() {
        return userService.getMe();
    }

    @PatchMapping("/me")
    public UserDto updateMe(@RequestBody UserUpdateRequest request) {
        return userService.updateMe(request);
    }
}
