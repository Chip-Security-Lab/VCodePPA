//SystemVerilog
module ITRC_AsyncLevel #(
    parameter PRIORITY = 4'hF
)(
    input clk,
    input rst_async,
    input [15:0] int_level,
    input en,
    output reg [3:0] int_id
);

    // Stage 1: Input masking and first level encoding
    reg [15:0] masked_int_stage1;
    reg [3:0] int_id_stage1;
    reg valid_stage1;
    
    // Stage 2: Second level encoding
    reg [3:0] int_id_stage2;
    reg valid_stage2;
    
    // Stage 3: Final output
    reg [3:0] int_id_stage3;
    reg valid_stage3;
    
    // Reset synchronization
    reg reset_sync;
    always @(posedge clk, posedge rst_async) begin
        if (rst_async) 
            reset_sync <= 1'b1;
        else 
            reset_sync <= 1'b0;
    end
    
    // Stage 1: Input processing and first 8-bit encoding
    always @(posedge clk) begin
        if (reset_sync) begin
            masked_int_stage1 <= 16'h0;
            int_id_stage1 <= 4'h0;
            valid_stage1 <= 1'b0;
        end else begin
            masked_int_stage1 <= int_level & {16{en}};
            valid_stage1 <= en;
            
            if (masked_int_stage1[15:8] != 8'h0) begin
                if (masked_int_stage1[15]) int_id_stage1 <= 4'hF;
                else if (masked_int_stage1[14]) int_id_stage1 <= 4'hE;
                else if (masked_int_stage1[13]) int_id_stage1 <= 4'hD;
                else if (masked_int_stage1[12]) int_id_stage1 <= 4'hC;
                else if (masked_int_stage1[11]) int_id_stage1 <= 4'hB;
                else if (masked_int_stage1[10]) int_id_stage1 <= 4'hA;
                else if (masked_int_stage1[9]) int_id_stage1 <= 4'h9;
                else int_id_stage1 <= 4'h8;
            end else begin
                int_id_stage1 <= 4'h0;
            end
        end
    end
    
    // Stage 2: Second 8-bit encoding
    always @(posedge clk) begin
        if (reset_sync) begin
            int_id_stage2 <= 4'h0;
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
            
            if (masked_int_stage1[7:0] != 8'h0) begin
                if (masked_int_stage1[7]) int_id_stage2 <= 4'h7;
                else if (masked_int_stage1[6]) int_id_stage2 <= 4'h6;
                else if (masked_int_stage1[5]) int_id_stage2 <= 4'h5;
                else if (masked_int_stage1[4]) int_id_stage2 <= 4'h4;
                else if (masked_int_stage1[3]) int_id_stage2 <= 4'h3;
                else if (masked_int_stage1[2]) int_id_stage2 <= 4'h2;
                else if (masked_int_stage1[1]) int_id_stage2 <= 4'h1;
                else int_id_stage2 <= 4'h0;
            end else begin
                int_id_stage2 <= int_id_stage1;
            end
        end
    end
    
    // Stage 3: Final output selection
    always @(posedge clk) begin
        if (reset_sync) begin
            int_id <= 4'h0;
            valid_stage3 <= 1'b0;
        end else begin
            valid_stage3 <= valid_stage2;
            int_id <= int_id_stage2;
        end
    end
    
endmodule