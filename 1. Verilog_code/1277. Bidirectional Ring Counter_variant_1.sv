//SystemVerilog
module bidir_ring_counter (
    input  wire        clk,      // System clock
    input  wire        rst,      // Synchronous reset
    input  wire        dir,      // Direction control (0: right, 1: left)
    output reg  [3:0]  q_out     // Counter output
);
    // Control signals
    reg        rst_r;            // Registered reset
    reg        dir_r;            // Registered direction
    reg [1:0]  ctrl_state;       // Control state for the counter
    
    // Pipeline stage 1: Register control inputs
    always @(posedge clk) begin
        rst_r <= rst;
        dir_r <= dir;
    end
    
    // Pipeline stage 2: Generate control state
    always @(posedge clk) begin
        ctrl_state <= {rst_r, dir_r};
    end
    
    // Pipeline stage 3: Apply counter operation based on control
    always @(posedge clk) begin
        case(ctrl_state)
            2'b10, 
            2'b11:   q_out <= 4'b0001;                 // Reset has priority
            2'b01:   q_out <= {q_out[2:0], q_out[3]};  // Left shift  
            2'b00:   q_out <= {q_out[0], q_out[3:1]};  // Right shift
            default: q_out <= 4'b0001;                 // Safe default
        endcase
    end
endmodule