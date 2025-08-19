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
    reg [15:0] masked_int_stage1_buf;
    reg [3:0] int_id_stage1;
    reg valid_stage1;
    
    // Stage 2: Second level encoding
    reg [3:0] int_id_stage2;
    reg valid_stage2;
    
    // Stage 1 logic
    always @(posedge clk) begin
        if (rst_async) begin
            masked_int_stage1 <= 16'h0;
            masked_int_stage1_buf <= 16'h0;
            int_id_stage1 <= 4'h0;
            valid_stage1 <= 1'b0;
        end else begin
            masked_int_stage1 <= int_level & {16{en}};
            masked_int_stage1_buf <= masked_int_stage1;
            valid_stage1 <= 1'b1;
            
            // First level priority encoding (bits 15:8)
            if (masked_int_stage1[15]) int_id_stage1 <= 4'hF;
            else if (masked_int_stage1[14]) int_id_stage1 <= 4'hE;
            else if (masked_int_stage1[13]) int_id_stage1 <= 4'hD;
            else if (masked_int_stage1[12]) int_id_stage1 <= 4'hC;
            else if (masked_int_stage1[11]) int_id_stage1 <= 4'hB;
            else if (masked_int_stage1[10]) int_id_stage1 <= 4'hA;
            else if (masked_int_stage1[9]) int_id_stage1 <= 4'h9;
            else if (masked_int_stage1[8]) int_id_stage1 <= 4'h8;
            else int_id_stage1 <= 4'h0;
        end
    end
    
    // Stage 2 logic
    always @(posedge clk) begin
        if (rst_async) begin
            int_id_stage2 <= 4'h0;
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
            
            // Second level priority encoding (bits 7:0)
            if (masked_int_stage1_buf[7]) int_id_stage2 <= 4'h7;
            else if (masked_int_stage1_buf[6]) int_id_stage2 <= 4'h6;
            else if (masked_int_stage1_buf[5]) int_id_stage2 <= 4'h5;
            else if (masked_int_stage1_buf[4]) int_id_stage2 <= 4'h4;
            else if (masked_int_stage1_buf[3]) int_id_stage2 <= 4'h3;
            else if (masked_int_stage1_buf[2]) int_id_stage2 <= 4'h2;
            else if (masked_int_stage1_buf[1]) int_id_stage2 <= 4'h1;
            else if (masked_int_stage1_buf[0]) int_id_stage2 <= 4'h0;
            else int_id_stage2 <= int_id_stage1;
        end
    end
    
    // Output stage
    always @(posedge clk) begin
        if (rst_async) begin
            int_id <= 4'h0;
        end else if (valid_stage2) begin
            int_id <= int_id_stage2;
        end
    end

endmodule