//SystemVerilog
module pl_reg_rotate #(parameter W=8) (
    input clk, load, rotate,
    input [W-1:0] d_in,
    output [W-1:0] q
);
    // Intermediate signals for optimized register retiming
    reg [W-1:0] q_reg;
    reg load_reg, rotate_reg;
    reg [W-1:0] d_in_reg;
    reg [W-1:0] rotated_data;
    
    // Register input control signals and data
    always @(posedge clk) begin
        load_reg <= load;
        rotate_reg <= rotate;
        d_in_reg <= d_in;
    end
    
    // Pre-compute rotated value
    always @(*) begin
        rotated_data = {q_reg[W-2:0], q_reg[W-1]};
    end
    
    // Main register logic moved earlier in the pipeline
    always @(posedge clk) begin
        if (load_reg) q_reg <= d_in_reg;
        else if (rotate_reg) q_reg <= rotated_data;
    end
    
    // Output assignment
    assign q = q_reg;
    
endmodule