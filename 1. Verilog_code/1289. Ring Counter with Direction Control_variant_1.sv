//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// Module: direction_ring_counter
// Description: Bidirectional ring counter with pipeline structure
// Standard: IEEE 1364-2005 Verilog
///////////////////////////////////////////////////////////////////////////////
module direction_ring_counter (
    input  wire       clk,      // System clock
    input  wire       rst,      // Synchronous reset
    input  wire       dir_sel,  // Direction select (0: left, 1: right)
    output reg  [3:0] q_out     // Ring counter output
);

    // Pipeline registers for improved timing
    reg dir_sel_r;
    reg [3:0] q_curr;
    reg [3:0] q_next;
    
    // Stage 1: Direction selection and input capture
    always @(posedge clk) begin
        if (rst) begin
            dir_sel_r <= 1'b0;
            q_curr <= 4'b0001;
        end else begin
            dir_sel_r <= dir_sel;
            q_curr <= q_out;
        end
    end
    
    // Stage 2: Next state computation (combinational)
    always @(*) begin
        if (dir_sel_r)
            q_next = {q_curr[0], q_curr[3:1]}; // Shift right
        else
            q_next = {q_curr[2:0], q_curr[3]}; // Shift left
    end
    
    // Stage 3: Output register stage
    always @(posedge clk) begin
        if (rst)
            q_out <= 4'b0001;
        else
            q_out <= q_next;
    end

endmodule