//SystemVerilog
module Gen_XNOR (
    input  wire        clk,       // Clock signal
    input  wire        rst_n,     // Active-low reset
    input  wire [15:0] vec1,      // Input vector 1
    input  wire [15:0] vec2,      // Input vector 2
    output reg  [15:0] result     // Output result vector
);
    // Internal pipeline registers
    reg [15:0] vec1_stage1;
    reg [15:0] vec2_stage1;
    reg [15:0] xnor_result_stage2;
    
    // Stage 1: Input Registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vec1_stage1 <= 16'h0000;
            vec2_stage1 <= 16'h0000;
        end else begin
            vec1_stage1 <= vec1;
            vec2_stage1 <= vec2;
        end
    end
    
    // Stage 2: XNOR Computation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xnor_result_stage2 <= 16'h0000;
        end else begin
            // Split the computation for better balancing
            xnor_result_stage2[7:0]  <= vec1_stage1[7:0] ~^ vec2_stage1[7:0];
            xnor_result_stage2[15:8] <= vec1_stage1[15:8] ~^ vec2_stage1[15:8];
        end
    end
    
    // Stage 3: Output Registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= 16'h0000;
        end else begin
            result <= xnor_result_stage2;
        end
    end
    
endmodule