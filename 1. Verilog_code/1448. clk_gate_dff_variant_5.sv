//SystemVerilog
module clk_gate_dff (
    input  wire clk,
    input  wire en,
    input  wire d,
    output reg  q
);
    // Stage 1: Clock gating control path
    reg en_stage1;
    reg valid_stage1;
    
    always @(posedge clk) begin
        en_stage1 <= en;
        valid_stage1 <= 1'b1; // Valid signal for stage 1
    end
    
    // Generate gated clock
    wire gated_clk;
    assign gated_clk = clk & en_stage1;
    
    // Stage 2: Data path
    reg d_stage2;
    reg valid_stage2;
    
    always @(posedge clk) begin
        if (valid_stage1) begin
            d_stage2 <= d;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Output stage
    always @(posedge clk) begin
        if (valid_stage2 && en_stage1) begin
            q <= d_stage2;
        end
    end
    
endmodule