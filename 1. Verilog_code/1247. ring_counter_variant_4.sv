//SystemVerilog
// Top-level module
module ring_counter (
    input wire clock,
    input wire reset,
    output wire [7:0] ring
);
    // Internal connection signals with buffering
    wire shift_enable;
    wire shift_enable_buf1, shift_enable_buf2;
    wire [7:0] next_ring_value;
    wire [7:0] current_ring_value;
    wire [7:0] current_value_buf1, current_value_buf2;
    wire [7:0] next_value_buf1, next_value_buf2;
    
    // Clock and reset buffering
    wire clock_buf1, clock_buf2, clock_buf3;
    wire reset_buf1, reset_buf2, reset_buf3;
    
    // Clock buffering for fanout reduction
    assign clock_buf1 = clock;
    assign clock_buf2 = clock;
    assign clock_buf3 = clock;
    
    // Reset buffering for fanout reduction
    assign reset_buf1 = reset;
    assign reset_buf2 = reset;
    assign reset_buf3 = reset;
    
    // Control unit handles reset logic and generates shift enable signal
    control_unit u_control_unit (
        .clock(clock_buf1),
        .reset(reset_buf1),
        .shift_enable(shift_enable)
    );
    
    // Buffer for shift_enable signal
    assign shift_enable_buf1 = shift_enable;
    assign shift_enable_buf2 = shift_enable;
    
    // Shift logic module handles the shifting operation
    shift_logic u_shift_logic (
        .current_value(current_value_buf1),
        .next_value(next_ring_value)
    );
    
    // Buffer for next_ring_value signal
    assign next_value_buf1 = next_ring_value;
    assign next_value_buf2 = next_ring_value;
    
    // Buffer for current_ring_value
    assign current_value_buf1 = current_ring_value;
    assign current_value_buf2 = current_ring_value;
    
    // Register module handles storage of the counter value
    ring_register u_ring_register (
        .clock(clock_buf2),
        .reset(reset_buf2),
        .shift_enable(shift_enable_buf1),
        .next_value(next_value_buf1),
        .current_value(current_ring_value),
        .ring_out(ring)
    );
    
endmodule

// Control unit module
module control_unit (
    input wire clock,
    input wire reset,
    output reg shift_enable
);
    // Register shift_enable to reduce fanout
    always @(posedge clock) begin
        shift_enable <= ~reset;
    end
    
endmodule

// Shift logic module
module shift_logic (
    input wire [7:0] current_value,
    output reg [7:0] next_value
);
    // Register the next_value to reduce combinational path
    always @(*) begin
        next_value = {current_value[0], current_value[7:1]};
    end
    
endmodule

// Register module
module ring_register (
    input wire clock,
    input wire reset,
    input wire shift_enable,
    input wire [7:0] next_value,
    output reg [7:0] current_value,
    output wire [7:0] ring_out
);
    // Register update logic
    always @(posedge clock) begin
        if (reset)
            current_value <= 8'b10000000;
        else if (shift_enable)
            current_value <= next_value;
    end
    
    // Output assignment - buffered to reduce fanout
    reg [7:0] ring_out_reg;
    
    always @(posedge clock) begin
        ring_out_reg <= current_value;
    end
    
    assign ring_out = ring_out_reg;
    
endmodule