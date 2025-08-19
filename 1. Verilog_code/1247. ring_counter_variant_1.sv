//SystemVerilog
// Top level module - Ring Counter Controller
module ring_counter (
    input wire clock, reset,
    output wire [7:0] ring
);
    // Internal signals
    wire shift_enable;
    wire [7:0] next_ring_value;
    wire [7:0] current_ring_value;
    
    // Instantiate control unit
    control_unit u_control (
        .clock(clock),
        .reset(reset),
        .shift_enable(shift_enable)
    );
    
    // Instantiate shift logic unit
    shift_logic u_shift_logic (
        .current_value(current_ring_value),
        .next_value(next_ring_value)
    );
    
    // Instantiate register unit
    register_unit u_register (
        .clock(clock),
        .reset(reset),
        .enable(shift_enable),
        .next_value(next_ring_value),
        .current_value(current_ring_value),
        .ring_out(ring)
    );
    
endmodule

// Control unit - Manages the shift enable signal
module control_unit (
    input wire clock, reset,
    output reg shift_enable
);
    // Default always enable shifting when not in reset
    always @(posedge clock or posedge reset) begin
        if (reset)
            shift_enable <= 1'b0;
        else
            shift_enable <= 1'b1;
    end
endmodule

// Shift logic unit - Calculates the next ring value
module shift_logic (
    input wire [7:0] current_value,
    output wire [7:0] next_value
);
    // Perform the ring shift operation
    assign next_value = {current_value[0], current_value[7:1]};
endmodule

// Register unit - Stores the current state and handles reset
module register_unit (
    input wire clock, reset, enable,
    input wire [7:0] next_value,
    output reg [7:0] current_value,
    output wire [7:0] ring_out
);
    // Update the register value on clock edge
    always @(posedge clock or posedge reset) begin
        if (reset)
            current_value <= 8'b10000000;
        else if (enable)
            current_value <= next_value;
    end
    
    // Connect internal register to output
    assign ring_out = current_value;
endmodule