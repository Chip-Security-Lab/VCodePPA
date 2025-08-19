//SystemVerilog
module cdc_arbiter #(
    parameter WIDTH = 4
) (
    input clk_a, clk_b, rst_n,
    input [WIDTH-1:0] req_a,
    output [WIDTH-1:0] grant_b
);
    // CDC synchronization stages
    reg [WIDTH-1:0] sync0_stage1, sync1_stage2;
    
    // Pipeline stages for arbitration
    reg [WIDTH-1:0] req_stage3;
    reg [WIDTH-1:0] masked_req_stage4;
    reg [WIDTH-1:0] grant_b_reg_stage5;
    
    // Valid signals for pipeline control
    reg valid_stage2, valid_stage3, valid_stage4, valid_stage5;
    
    // Combined pipeline stages - all share the same clock and reset
    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n) begin
            // Stage 1: First CDC synchronization flip-flop
            sync0_stage1 <= {WIDTH{1'b0}};
            
            // Stage 2: Second CDC synchronization flip-flop
            sync1_stage2 <= {WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
            
            // Stage 3: Register synchronized request
            req_stage3 <= {WIDTH{1'b0}};
            valid_stage3 <= 1'b0;
            
            // Stage 4: Compute masked request
            masked_req_stage4 <= {WIDTH{1'b0}};
            valid_stage4 <= 1'b0;
            
            // Stage 5: Final grant output register
            grant_b_reg_stage5 <= {WIDTH{1'b0}};
            valid_stage5 <= 1'b0;
        end else begin
            // Stage 1: First CDC synchronization flip-flop
            sync0_stage1 <= req_a;
            
            // Stage 2: Second CDC synchronization flip-flop
            sync1_stage2 <= sync0_stage1;
            valid_stage2 <= 1'b1; // After reset, pipeline becomes valid
            
            // Stage 3: Register synchronized request
            req_stage3 <= sync1_stage2;
            valid_stage3 <= valid_stage2;
            
            // Stage 4: Compute masked request (lowest bit set)
            masked_req_stage4 <= req_stage3 & (~req_stage3 + 1'b1);
            valid_stage4 <= valid_stage3;
            
            // Stage 5: Final grant output register
            grant_b_reg_stage5 <= masked_req_stage4;
            valid_stage5 <= valid_stage4;
        end
    end
    
    // Output assignment
    assign grant_b = grant_b_reg_stage5;
    
endmodule