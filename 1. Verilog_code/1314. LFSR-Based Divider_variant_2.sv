//SystemVerilog
module lfsr_divider (
    input  wire i_clk,
    input  wire i_rst,
    output wire o_clk_div
);
    // Extended pipeline registers
    reg [4:0] lfsr_stage1;
    reg [4:0] lfsr_stage2;
    reg [4:0] lfsr_stage3;
    reg [4:0] lfsr_stage4;
    
    // Feedback path registers
    reg feedback_stage1;
    reg feedback_stage2;
    
    // Feedback computation split into stages
    wire xor_result;
    assign xor_result = lfsr_stage1[4] ^ lfsr_stage1[2];
    
    // Stage 1: Initial LFSR state and feedback computation
    always @(posedge i_clk) begin
        if (i_rst)
            lfsr_stage1 <= 5'h1f;
        else
            lfsr_stage1 <= {lfsr_stage1[3:0], feedback_stage2};
            
        feedback_stage1 <= xor_result;
    end
    
    // Stage 2: Pipeline feedback path
    always @(posedge i_clk) begin
        feedback_stage2 <= feedback_stage1;
    end
    
    // Stage 3: Buffer LFSR for fanout distribution
    always @(posedge i_clk) begin
        lfsr_stage2 <= lfsr_stage1;
    end
    
    // Stage 4: Additional buffering for high fanout paths
    always @(posedge i_clk) begin
        lfsr_stage3 <= lfsr_stage2;
    end
    
    // Stage 5: Final output buffering
    always @(posedge i_clk) begin
        lfsr_stage4 <= lfsr_stage3;
    end
    
    // Use deepest pipeline stage for output
    assign o_clk_div = lfsr_stage4[4];
endmodule