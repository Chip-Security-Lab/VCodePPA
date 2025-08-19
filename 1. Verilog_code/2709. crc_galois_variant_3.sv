//SystemVerilog
module crc_galois (
    input clk, rst_n,
    input [7:0] data,
    output reg [7:0] crc
);
    parameter POLY = 8'hD5;
    
    // Pipeline stages
    reg [7:0] stage0, stage1, stage2, stage3;
    reg [7:0] stage4, stage5, stage6;
    
    // Initial XOR stage
    wire [7:0] xord = crc ^ data;
    
    // Pipeline with if-else structure
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage0 <= 8'h00;
            stage1 <= 8'h00;
            stage2 <= 8'h00;
            stage3 <= 8'h00;
            stage4 <= 8'h00;
            stage5 <= 8'h00;
            stage6 <= 8'h00;
            crc <= 8'h00;
        end else begin
            // Stage 0 computation
            if (xord[7]) begin
                stage0 <= {xord[6:0], 1'b0} ^ POLY;
            end else begin
                stage0 <= {xord[6:0], 1'b0};
            end
            
            // Stage 1 computation
            if (stage0[7]) begin
                stage1 <= {stage0[6:0], 1'b0} ^ POLY;
            end else begin
                stage1 <= {stage0[6:0], 1'b0};
            end
            
            // Stage 2 computation
            if (stage1[7]) begin
                stage2 <= {stage1[6:0], 1'b0} ^ POLY;
            end else begin
                stage2 <= {stage1[6:0], 1'b0};
            end
            
            // Stage 3 computation
            if (stage2[7]) begin
                stage3 <= {stage2[6:0], 1'b0} ^ POLY;
            end else begin
                stage3 <= {stage2[6:0], 1'b0};
            end
            
            // Stage 4 computation
            if (stage3[7]) begin
                stage4 <= {stage3[6:0], 1'b0} ^ POLY;
            end else begin
                stage4 <= {stage3[6:0], 1'b0};
            end
            
            // Stage 5 computation
            if (stage4[7]) begin
                stage5 <= {stage4[6:0], 1'b0} ^ POLY;
            end else begin
                stage5 <= {stage4[6:0], 1'b0};
            end
            
            // Stage 6 computation
            if (stage5[7]) begin
                stage6 <= {stage5[6:0], 1'b0} ^ POLY;
            end else begin
                stage6 <= {stage5[6:0], 1'b0};
            end
            
            // CRC output computation
            if (stage6[7]) begin
                crc <= {stage6[6:0], 1'b0} ^ POLY;
            end else begin
                crc <= {stage6[6:0], 1'b0};
            end
        end
    end
endmodule