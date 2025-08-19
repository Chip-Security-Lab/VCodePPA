//SystemVerilog
module bitserial_crc(
    input wire clk,
    input wire rst,
    input wire bit_in,
    input wire bit_valid,
    output reg [7:0] crc8_out
);

    parameter CRC_POLY = 8'h07; // x^8 + x^2 + x + 1
    
    // Stage 1: Input and feedback calculation
    reg bit_in_stage1;
    reg bit_valid_stage1;
    reg [7:0] crc8_stage1;
    wire feedback_stage1;
    
    // Stage 2: CRC shift and polynomial XOR computation
    reg feedback_stage2;
    reg bit_valid_stage2;
    reg [7:0] crc8_stage2;
    wire [7:0] crc_shift_stage2;
    wire [7:0] crc_poly_stage2;
    wire [7:0] crc_next_stage2;
    
    // Stage 1 logic: Input and feedback calculation
    assign feedback_stage1 = crc8_stage1[7] ^ bit_in_stage1;
    
    // Stage 2 logic: CRC shift and polynomial XOR
    assign crc_shift_stage2 = {crc8_stage2[6:0], 1'b0};
    assign crc_poly_stage2 = feedback_stage2 ? CRC_POLY : 8'h00;
    assign crc_next_stage2 = crc_shift_stage2 ^ crc_poly_stage2;
    
    // Pipeline stage registers
    always @(posedge clk) begin
        if (rst) begin
            // Reset stage 1 registers
            bit_in_stage1 <= 1'b0;
            bit_valid_stage1 <= 1'b0;
            crc8_stage1 <= 8'h00;
            
            // Reset stage 2 registers
            feedback_stage2 <= 1'b0;
            bit_valid_stage2 <= 1'b0;
            crc8_stage2 <= 8'h00;
            
            // Reset output
            crc8_out <= 8'h00;
        end
        else begin
            // Stage 1: Register inputs and current CRC
            bit_in_stage1 <= bit_in;
            bit_valid_stage1 <= bit_valid;
            crc8_stage1 <= crc8_out;
            
            // Stage 2: Register feedback and propagate valid signal
            feedback_stage2 <= feedback_stage1;
            bit_valid_stage2 <= bit_valid_stage1;
            crc8_stage2 <= crc8_stage1;
            
            // Output stage: Update CRC based on stage 2 calculation
            if (bit_valid_stage2) begin
                crc8_out <= crc_next_stage2;
            end
        end
    end

endmodule