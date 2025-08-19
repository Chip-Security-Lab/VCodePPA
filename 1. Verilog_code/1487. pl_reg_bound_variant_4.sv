//SystemVerilog - IEEE 1364-2005
module pl_reg_bound #(parameter W=8, MAX=8'h7F) (
    input clk, load,
    input [W-1:0] d_in,
    output reg [W-1:0] q
);
    // Pipeline registers for critical path cutting
    reg [W-1:0] d_in_reg;
    reg load_reg;
    reg borrow_reg;
    reg [W-1:0] difference_reg;
    
    // Stage 1: Register inputs and compute subtraction
    always @(posedge clk) begin
        d_in_reg <= d_in;
        load_reg <= load;
        {borrow_reg, difference_reg} <= {1'b0, MAX} - {1'b0, d_in};
    end
    
    // Stage 2: Apply bounded logic based on comparison result
    always @(posedge clk) begin
        if (load_reg)
            q <= borrow_reg ? MAX : d_in_reg;
    end
endmodule