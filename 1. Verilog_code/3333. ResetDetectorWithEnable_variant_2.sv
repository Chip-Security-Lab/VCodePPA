//SystemVerilog
// Top-level module: Hierarchical Reset Detector with Enable (Optimized)
module ResetDetectorWithEnable (
    input  wire clk,
    input  wire rst_n,
    input  wire enable,
    output wire reset_detected
);

    wire reset_pulse;
    wire enable_clear;
    wire reset_state;

    // Optimized Reset Pulse Generator
    ResetPulseGenOpt u_reset_pulse_gen (
        .clk          (clk),
        .rst_n        (rst_n),
        .reset_pulse  (reset_pulse)
    );

    // Optimized Enable Clear Detector
    EnableClearGenOpt u_enable_clear_gen (
        .clk          (clk),
        .enable       (enable),
        .enable_clear (enable_clear)
    );

    // Optimized Reset State Register
    ResetStateRegOpt u_reset_state_reg (
        .clk             (clk),
        .reset_pulse     (reset_pulse),
        .enable_clear    (enable_clear),
        .reset_detected  (reset_state)
    );

    assign reset_detected = reset_state;

endmodule

// -----------------------------------------------------------------------------
// Optimized Reset Pulse Generator: Generates a pulse when reset is asserted (active low)
// -----------------------------------------------------------------------------
module ResetPulseGenOpt (
    input  wire clk,
    input  wire rst_n,
    output reg  reset_pulse
);
    reg rst_n_d;
    always @(posedge clk) begin
        rst_n_d <= rst_n;
        reset_pulse <= rst_n_d & ~rst_n;
    end
endmodule

// -----------------------------------------------------------------------------
// Optimized Enable Clear Detector: Generates a clear signal when enable is asserted
// -----------------------------------------------------------------------------
module EnableClearGenOpt (
    input  wire clk,
    input  wire enable,
    output reg  enable_clear
);
    reg enable_d;
    always @(posedge clk) begin
        enable_d <= enable;
        enable_clear <= ~enable_d & enable;
    end
endmodule

// -----------------------------------------------------------------------------
// Optimized Reset State Register: Balanced logic for set/clear
// -----------------------------------------------------------------------------
module ResetStateRegOpt (
    input  wire clk,
    input  wire reset_pulse,
    input  wire enable_clear,
    output reg  reset_detected
);
    always @(posedge clk) begin
        case ({reset_pulse, enable_clear})
            2'b10: reset_detected <= 1'b1;
            2'b01: reset_detected <= 1'b0;
            default: reset_detected <= reset_detected;
        endcase
    end
endmodule