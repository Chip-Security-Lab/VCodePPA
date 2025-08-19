//SystemVerilog
module resource_optimized_crc8(
    input wire clk,
    input wire rst,
    input wire data_bit,
    input wire bit_valid,
    output reg [7:0] crc
);
    parameter [7:0] POLY = 8'hD5;
    
    // Internal signals
    wire feedback;
    reg [7:0] crc_next;
    
    // Stage registers for pipelining
    reg feedback_stage;
    reg [6:0] crc_shift_stage;
    
    // Calculate feedback
    assign feedback = crc[7] ^ data_bit;
    
    // Two-stage calculation to reduce critical path
    always @(*) begin
        // Use direct indexing to avoid full bus operations
        crc_next = {crc_shift_stage, 1'b0};
        
        // Conditional XOR using pre-calculated feedback
        if (feedback_stage)
            crc_next = crc_next ^ POLY;
    end
    
    // Main CRC register with optimized buffering strategy
    always @(posedge clk) begin
        if (rst) begin
            crc <= 8'h00;
            feedback_stage <= 1'b0;
            crc_shift_stage <= 7'h00;
        end else if (bit_valid) begin
            // Update CRC with pre-calculated next value
            crc <= crc_next;
            
            // Stage registers for next cycle
            feedback_stage <= feedback;
            crc_shift_stage <= crc[6:0];
        end
    end
endmodule