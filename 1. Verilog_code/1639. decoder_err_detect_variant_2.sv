//SystemVerilog
// SystemVerilog

// Address validation module - checks if address is within valid range
module addr_validator #(
    parameter MAX_ADDR = 16'hFFFF
) (
    input  [15:0] addr,
    output        valid
);
    assign valid = (addr < MAX_ADDR);
endmodule

// Error detection module - generates error signal for out-of-range addresses
module error_detector #(
    parameter MAX_ADDR = 16'hFFFF
) (
    input  [15:0] addr,
    output        error
);
    assign error = (addr >= MAX_ADDR);
endmodule

// Address decoder with error detection - combines validation and error detection
module addr_decoder #(
    parameter MAX_ADDR = 16'hFFFF
) (
    input  [15:0] addr,
    output        valid,
    output        error
);
    // Instantiate address validator
    addr_validator #(MAX_ADDR) u_validator (
        .addr  (addr),
        .valid (valid)
    );
    
    // Instantiate error detector
    error_detector #(MAX_ADDR) u_error_detector (
        .addr  (addr),
        .error (error)
    );
endmodule

// Top-level module - provides address decoding with error detection
module decoder_err_detect #(
    parameter MAX_ADDR = 16'hFFFF
) (
    input  [15:0] addr,
    output        select,
    output        err
);
    // Instantiate address decoder
    addr_decoder #(MAX_ADDR) u_addr_decoder (
        .addr  (addr),
        .valid (select),
        .error (err)
    );
endmodule