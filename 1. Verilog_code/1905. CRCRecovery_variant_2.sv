//SystemVerilog
module CRCRecovery #(parameter WIDTH=8) (
    input clk, 
    input [WIDTH+3:0] coded_in, // 4-bit CRC
    output reg [WIDTH-1:0] data_out,
    output reg crc_error
);
    // Pipeline stage 1: Calculate CRC
    reg [3:0] calc_crc_stage1;
    reg [WIDTH-1:0] data_stage1;
    
    // Pipeline stage 2: Error detection and data output
    reg crc_error_stage2;
    
    // First pipeline stage: CRC calculation
    always @(posedge clk) begin
        calc_crc_stage1 <= coded_in[WIDTH+3:WIDTH] ^ coded_in[WIDTH-1:0];
        data_stage1 <= coded_in[WIDTH-1:0]; // Store data for next stage
    end
    
    // Second pipeline stage: Error detection
    always @(posedge clk) begin
        crc_error_stage2 <= |calc_crc_stage1;
    end
    
    // Third pipeline stage: Data output
    always @(posedge clk) begin
        crc_error <= crc_error_stage2;
        
        if (crc_error_stage2) begin
            data_out <= {WIDTH{1'b1}}; // 全1输出，使用参数化宽度
        end else begin
            data_out <= data_stage1;
        end
    end
endmodule