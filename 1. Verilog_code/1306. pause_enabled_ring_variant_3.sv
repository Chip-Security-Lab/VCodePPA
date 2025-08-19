//SystemVerilog

// Top-level module
module pause_enabled_ring (
    input  wire        clk,
    input  wire        rst,
    input  wire        valid_in,  // Replaces 'pause' with valid signal
    output wire        ready_out, // New ready signal for handshaking
    output wire [3:0]  current_state
);
    
    // Internal connections
    wire shift_enable;
    wire data_transfer;
    
    // Submodule instances
    pause_controller u_pause_controller (
        .valid_in(valid_in),
        .ready_out(ready_out),
        .shift_enable(shift_enable)
    );
    
    ring_counter u_ring_counter (
        .clk(clk),
        .rst(rst),
        .shift_enable(shift_enable),
        .current_state(current_state)
    );
    
endmodule

// Pause controller with valid-ready handshake interface
module pause_controller (
    input  wire valid_in,  // Sender indicates data is valid
    output wire ready_out, // Receiver is ready for next data
    output wire shift_enable
);
    
    // Always ready to receive new control signals
    assign ready_out = 1'b1;
    
    // Generate shift enable signal based on valid-ready handshake
    assign shift_enable = ~valid_in & ready_out;
    
endmodule

// Ring counter submodule
module ring_counter #(
    parameter WIDTH = 4,
    parameter INIT_STATE = 4'b0001
)(
    input  wire              clk,
    input  wire              rst,
    input  wire              shift_enable,
    output reg  [WIDTH-1:0]  current_state
);
    
    always @(posedge clk) begin
        if (rst) 
            current_state <= INIT_STATE;
        else if (shift_enable) 
            current_state <= {current_state[0], current_state[WIDTH-1:1]};
    end
    
endmodule