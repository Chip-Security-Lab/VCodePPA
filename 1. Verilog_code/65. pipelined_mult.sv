module pipelined_mult (
    input clk,
    input [15:0] a, b,
    output reg [31:0] result
);
    reg [15:0] a_stage1, b_stage1;
    reg [31:0] partial_stage2;
    
    always @(posedge clk) begin
        // Stage 1: Input register
        a_stage1 <= a;
        b_stage1 <= b;
        
        // Stage 2: Partial product
        partial_stage2 <= a_stage1 * b_stage1;
        
        // Stage 3: Output register
        result <= partial_stage2;
    end
endmodule
