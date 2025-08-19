//SystemVerilog
module bitserial_crc(
    input wire clk,
    input wire rst,
    input wire bit_in,
    input wire bit_valid,
    output reg [7:0] crc8_out
);
    parameter CRC_POLY = 8'h07; // x^8 + x^2 + x + 1
    
    // Pipeline stage 1 registers
    reg bit_in_stage1;
    reg bit_valid_stage1;
    reg [7:0] crc_stage1;
    
    // Pipeline stage 2 registers
    reg feedback_stage2;
    reg [7:0] crc_stage2;
    
    // Pipeline stage 3 registers
    reg [7:0] crc_stage3;
    
    // Stage 1: Input sampling and initial shift
    always @(posedge clk) begin
        if (rst) begin
            bit_in_stage1 <= 1'b0;
            bit_valid_stage1 <= 1'b0;
            crc_stage1 <= 8'h00;
        end else begin
            bit_in_stage1 <= bit_in;
            bit_valid_stage1 <= bit_valid;
            crc_stage1 <= crc8_out;
        end
    end
    
    // Stage 2: Feedback calculation
    always @(posedge clk) begin
        if (rst) begin
            feedback_stage2 <= 1'b0;
            crc_stage2 <= 8'h00;
        end else begin
            feedback_stage2 <= crc_stage1[7] ^ bit_in_stage1;
            crc_stage2 <= {crc_stage1[6:0], 1'b0};
        end
    end
    
    // Stage 3: Final XOR and output
    always @(posedge clk) begin
        if (rst) begin
            crc_stage3 <= 8'h00;
            crc8_out <= 8'h00;
        end else begin
            if (bit_valid_stage1) begin
                crc_stage3 <= crc_stage2 ^ (feedback_stage2 ? CRC_POLY : 8'h00);
                crc8_out <= crc_stage3;
            end
        end
    end
endmodule