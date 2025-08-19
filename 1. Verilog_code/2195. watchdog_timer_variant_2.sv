//SystemVerilog
module watchdog_timer #(
    parameter TIMEOUT_WIDTH = 20
)(
    input wire clk_in,
    input wire clear_watchdog,
    input wire enable_watchdog,
    input wire [TIMEOUT_WIDTH-1:0] timeout_value,
    output wire system_reset
);
    // Internal signals for connecting sub-modules
    wire [TIMEOUT_WIDTH-1:0] counter_value;
    wire timeout_detected;
    
    // Counter module instance
    watchdog_counter #(
        .COUNTER_WIDTH(TIMEOUT_WIDTH)
    ) counter_inst (
        .clk_in(clk_in),
        .clear_counter(clear_watchdog),
        .enable_counter(enable_watchdog),
        .counter_value(counter_value)
    );
    
    // Timeout detector module instance (pure combinational logic)
    timeout_detector #(
        .COUNTER_WIDTH(TIMEOUT_WIDTH)
    ) detector_inst (
        .counter_value(counter_value),
        .timeout_threshold(timeout_value),
        .timeout_detected(timeout_detected)
    );
    
    // Reset controller module instance
    reset_controller reset_ctrl_inst (
        .clk_in(clk_in),
        .clear_reset(clear_watchdog),
        .timeout_detected(timeout_detected),
        .enable_watchdog(enable_watchdog),
        .system_reset(system_reset)
    );
    
endmodule

// Counter module with separated sequential and combinational logic
module watchdog_counter #(
    parameter COUNTER_WIDTH = 20
)(
    input wire clk_in,
    input wire clear_counter,
    input wire enable_counter,
    output wire [COUNTER_WIDTH-1:0] counter_value
);
    // Internal signals
    reg [COUNTER_WIDTH-1:0] counter_reg;
    wire [COUNTER_WIDTH-1:0] next_counter;
    
    // Combinational logic for next counter value
    assign next_counter = clear_counter ? {COUNTER_WIDTH{1'b0}} :
                         (enable_counter ? counter_reg + 1'b1 : counter_reg);
    
    // Sequential logic for counter register
    always @(posedge clk_in) begin
        counter_reg <= next_counter;
    end
    
    // Output assignment
    assign counter_value = counter_reg;
endmodule

// Timeout detection module (pure combinational logic)
module timeout_detector #(
    parameter COUNTER_WIDTH = 20
)(
    input wire [COUNTER_WIDTH-1:0] counter_value,
    input wire [COUNTER_WIDTH-1:0] timeout_threshold,
    output wire timeout_detected
);
    // Pure combinational comparison
    assign timeout_detected = (counter_value >= timeout_threshold);
endmodule

// Reset signal controller with separated logic
module reset_controller (
    input wire clk_in,
    input wire clear_reset,
    input wire timeout_detected,
    input wire enable_watchdog,
    output wire system_reset
);
    // Internal signals
    reg reset_reg;
    wire next_reset;
    
    // Combinational logic for next reset value
    assign next_reset = clear_reset ? 1'b0 :
                       (enable_watchdog && timeout_detected) ? 1'b1 : reset_reg;
    
    // Sequential logic for reset register
    always @(posedge clk_in) begin
        reset_reg <= next_reset;
    end
    
    // Output assignment
    assign system_reset = reset_reg;
endmodule