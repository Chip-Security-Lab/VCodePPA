//SystemVerilog
module priority_encoder_pipelined (
    input clk,
    input rst_n,
    input [7:0] requests,
    output reg [2:0] grant_id,
    output reg valid
);

    // Stage 1: Priority mask generation
    reg [7:0] priority_mask_stage1;
    reg [7:0] requests_stage1;
    
    // Stage 2: First level encoding
    reg [3:0] encoded_high_stage2;
    reg [3:0] encoded_low_stage2;
    reg [7:0] priority_mask_stage2;
    reg valid_stage2;
    
    // Stage 3: Final encoding
    reg [2:0] encoded_id_stage3;
    reg valid_stage3;
    
    // Stage 1: Generate priority mask
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_mask_stage1 <= 8'b0;
            requests_stage1 <= 8'b0;
        end else begin
            priority_mask_stage1 <= requests & (~requests + 1);
            requests_stage1 <= requests;
        end
    end
    
    // Stage 2: Split encoding into high and low nibbles
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            encoded_high_stage2 <= 4'b0;
            encoded_low_stage2 <= 4'b0;
            priority_mask_stage2 <= 8'b0;
            valid_stage2 <= 1'b0;
        end else begin
            // Encode high nibble (bits 7-4)
            encoded_high_stage2 <= priority_mask_stage1[7] ? 4'd7 :
                                  priority_mask_stage1[6] ? 4'd6 :
                                  priority_mask_stage1[5] ? 4'd5 :
                                  priority_mask_stage1[4] ? 4'd4 : 4'd0;
            
            // Encode low nibble (bits 3-0)
            encoded_low_stage2 <= priority_mask_stage1[3] ? 4'd3 :
                                 priority_mask_stage1[2] ? 4'd2 :
                                 priority_mask_stage1[1] ? 4'd1 : 4'd0;
            
            priority_mask_stage2 <= priority_mask_stage1;
            valid_stage2 <= |requests_stage1;
        end
    end
    
    // Stage 3: Final encoding selection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            encoded_id_stage3 <= 3'b0;
            valid_stage3 <= 1'b0;
        end else begin
            // Select between high and low nibble results
            encoded_id_stage3 <= (priority_mask_stage2[7:4] != 4'b0) ? 
                                encoded_high_stage2[2:0] : 
                                encoded_low_stage2[2:0];
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant_id <= 3'b0;
            valid <= 1'b0;
        end else begin
            grant_id <= encoded_id_stage3;
            valid <= valid_stage3;
        end
    end

endmodule