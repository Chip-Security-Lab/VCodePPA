//SystemVerilog
// IEEE 1364-2005
module BiDirShift #(parameter BITS=8) (
    input clk, rst, dir, s_in,
    output [BITS-1:0] q
);
    // Intermediate registers to pull back from output
    reg s_in_reg;
    reg dir_reg;
    reg [BITS-2:0] q_left_reg;   // For left shift path
    reg [BITS-1:1] q_right_reg;  // For right shift path
    
    // Register inputs to break critical path
    always @(posedge clk) begin
        if (rst) begin
            s_in_reg <= 0;
            dir_reg <= 0;
            q_left_reg <= 0;
            q_right_reg <= 0;
        end
        else begin
            s_in_reg <= s_in;
            dir_reg <= dir;
            q_left_reg <= q[BITS-2:0];
            q_right_reg <= q[BITS-1:1];
        end
    end
    
    // Output assignment using registered inputs
    // This moves the registers backward through the combinational logic
    assign q = dir_reg ? {q_left_reg, s_in_reg} : {s_in_reg, q_right_reg};
    
endmodule