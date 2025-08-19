//SystemVerilog
module hybrid_arbiter #(parameter WIDTH=4) (
    input clk, rst_n,
    input [WIDTH-1:0] req_i,
    output reg [WIDTH-1:0] grant_o
);
    // Stage 1 signals
    reg [WIDTH-1:0] req_stage1;
    reg [1:0] rr_ptr_stage1;
    reg [1:0] priority_select_stage1;
    reg priority_valid_stage1;
    reg valid_stage1;
    
    // Stage 2 signals
    reg [WIDTH-1:0] req_stage2;
    reg [1:0] rr_ptr_stage2;
    reg [1:0] priority_select_stage2;
    reg priority_valid_stage2;
    reg [1:0] rr_select_stage2;
    reg rr_valid_stage2;
    reg valid_stage2;
    
    // Combined Stage 1 (previous Stage 1 + Stage 2 logic)
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            req_stage1 <= 0;
            rr_ptr_stage1 <= 0;
            priority_select_stage1 <= 0;
            priority_valid_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            req_stage1 <= req_i;
            rr_ptr_stage1 <= rr_ptr_stage2;  // Feedback from stage 2
            
            // Priority logic for high priority channels (moved from old Stage 2)
            priority_valid_stage1 <= 0;
            if(req_i[3:2] == 2'b01 || req_i[3:2] == 2'b11) begin
                priority_select_stage1 <= 2'd2;  // Channel 2
                priority_valid_stage1 <= 1'b1;
            end else if(req_i[3:2] == 2'b10) begin
                priority_select_stage1 <= 2'd3;  // Channel 3
                priority_valid_stage1 <= 1'b1;
            end
            
            valid_stage1 <= 1'b1;
        end
    end
    
    // Stage 2 (previous Stage 3) - Round-robin arbitration and final output
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            req_stage2 <= 0;
            rr_ptr_stage2 <= 0;
            priority_select_stage2 <= 0;
            priority_valid_stage2 <= 0;
            rr_select_stage2 <= 0;
            rr_valid_stage2 <= 0;
            valid_stage2 <= 0;
            grant_o <= 0;
        end else if(valid_stage1) begin
            req_stage2 <= req_stage1;
            priority_select_stage2 <= priority_select_stage1;
            priority_valid_stage2 <= priority_valid_stage1;
            valid_stage2 <= valid_stage1;
            
            // Round-robin logic for low priority channels (only if no high priority)
            rr_valid_stage2 <= 0;
            if(!priority_valid_stage1) begin
                if(req_stage1[0] && (rr_ptr_stage1 == 2'd0 || !req_stage1[1])) begin
                    rr_select_stage2 <= 2'd0;
                    rr_ptr_stage2 <= 2'd1;
                    rr_valid_stage2 <= 1'b1;
                end else if(req_stage1[1]) begin
                    rr_select_stage2 <= 2'd1;
                    rr_ptr_stage2 <= 2'd0;
                    rr_valid_stage2 <= 1'b1;
                end else begin
                    rr_ptr_stage2 <= rr_ptr_stage1;
                end
            end else begin
                rr_ptr_stage2 <= rr_ptr_stage1;
            end
            
            // Final grant output
            grant_o <= 0;
            if(priority_valid_stage2) begin
                grant_o[priority_select_stage2] <= 1'b1;
            end else if(rr_valid_stage2) begin
                grant_o[rr_select_stage2] <= 1'b1;
            end
        end else begin
            valid_stage2 <= 0;
            grant_o <= 0;
        end
    end
endmodule