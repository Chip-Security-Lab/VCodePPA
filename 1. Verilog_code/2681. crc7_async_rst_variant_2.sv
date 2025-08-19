//SystemVerilog
module crc7_async_rst(
    input wire clk,
    input wire arst_n,
    input wire [6:0] data,
    output reg [6:0] crc_out
);
    reg [6:0] crc_stage1;
    reg [6:0] crc_stage2;
    wire feedback_stage1 = crc_stage1[6] ^ data[0];
    wire feedback_stage2 = crc_stage2[6] ^ data[0];
    
    always @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            crc_stage1 <= 7'h00;
            crc_stage2 <= 7'h00;
            crc_out <= 7'h00;
        end
        else begin
            // Stage 1
            crc_stage1[0] <= feedback_stage1;
            crc_stage1[1] <= crc_stage1[0];
            crc_stage1[2] <= crc_stage1[1];
            crc_stage1[3] <= crc_stage1[2] ^ feedback_stage1;
            crc_stage1[4] <= crc_stage1[3];
            crc_stage1[5] <= crc_stage1[4];
            crc_stage1[6] <= crc_stage1[5];
            
            // Stage 2
            crc_stage2[0] <= feedback_stage2;
            crc_stage2[1] <= crc_stage2[0];
            crc_stage2[2] <= crc_stage2[1];
            crc_stage2[3] <= crc_stage2[2] ^ feedback_stage2;
            crc_stage2[4] <= crc_stage2[3];
            crc_stage2[5] <= crc_stage2[4];
            crc_stage2[6] <= crc_stage2[5];
            
            // Final output
            crc_out <= crc_stage2;
        end
    end
endmodule