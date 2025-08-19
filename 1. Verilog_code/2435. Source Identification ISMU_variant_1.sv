//SystemVerilog
module source_id_ismu(
    input wire clk, rst_n,
    input wire [7:0] irq,
    input wire ack,
    output reg [2:0] src_id,
    output reg valid
);
    // Pipeline registers
    reg [7:0] pending_stage1;
    reg [7:0] pending_stage2;
    reg [2:0] src_id_stage1;
    reg valid_stage1;
    reg ack_stage1;
    
    // First pipeline stage: capture inputs and update pending
    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            pending_stage1 <= 8'h0;
            ack_stage1 <= 1'b0;
        end else begin
            pending_stage1 <= pending_stage2 | irq;
            ack_stage1 <= ack;
            
            if (ack)
                pending_stage1[src_id] <= 1'b0;
        end
    end
    
    // Second pipeline stage: priority encoding part 1 (lower 4 bits)
    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            pending_stage2 <= 8'h0;
            src_id_stage1 <= 3'h0;
            valid_stage1 <= 1'b0;
        end else begin
            pending_stage2 <= pending_stage1;
            
            // Lower 4 bits priority encoding
            if (pending_stage1[0]) begin
                src_id_stage1 <= 3'd0;
                valid_stage1 <= 1'b1;
            end else if (pending_stage1[1]) begin
                src_id_stage1 <= 3'd1;
                valid_stage1 <= 1'b1;
            end else if (pending_stage1[2]) begin
                src_id_stage1 <= 3'd2;
                valid_stage1 <= 1'b1;
            end else if (pending_stage1[3]) begin
                src_id_stage1 <= 3'd3;
                valid_stage1 <= 1'b1;
            end else begin
                // Will be determined in the next stage
                src_id_stage1 <= 3'h0;
                valid_stage1 <= 1'b0;
            end
        end
    end
    
    // Third pipeline stage: priority encoding part 2 (upper 4 bits) and final output
    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            src_id <= 3'h0;
            valid <= 1'b0;
        end else begin
            if (valid_stage1) begin
                // Use results from stage 1
                src_id <= src_id_stage1;
                valid <= valid_stage1;
            end else begin
                // Upper 4 bits priority encoding
                if (pending_stage2[4]) begin
                    src_id <= 3'd4;
                    valid <= 1'b1;
                end else if (pending_stage2[5]) begin
                    src_id <= 3'd5;
                    valid <= 1'b1;
                end else if (pending_stage2[6]) begin
                    src_id <= 3'd6;
                    valid <= 1'b1;
                end else if (pending_stage2[7]) begin
                    src_id <= 3'd7;
                    valid <= 1'b1;
                end else begin
                    valid <= 1'b0;
                    src_id <= 3'h0;
                end
            end
        end
    end
endmodule