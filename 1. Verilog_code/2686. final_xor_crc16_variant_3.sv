//SystemVerilog
module final_xor_crc16(
    input wire clk,
    input wire reset,
    input wire [7:0] data,
    input wire data_valid,
    input wire calc_done,
    output reg [15:0] crc_out
);
    parameter [15:0] POLY = 16'h1021;
    parameter [15:0] FINAL_XOR = 16'hFFFF;
    
    // Stage 1 registers
    reg [15:0] crc_stage1;
    reg data_valid_stage1;
    reg [7:0] data_stage1;
    reg calc_done_stage1;
    
    // Stage 2 registers
    reg [15:0] crc_stage2;
    reg calc_done_stage2;
    
    // Stage 3 registers
    reg [15:0] crc_stage3;
    reg calc_done_stage3;
    
    // Optimized logic for CRC calculation
    wire crc_feedback = crc_stage1[15];
    wire data_bit = data_valid ? data[0] : 1'b0;
    wire bit_result = crc_feedback ^ data_bit;
    wire [15:0] shifted_crc = {crc_stage1[14:0], 1'b0};
    wire [15:0] crc_next = shifted_crc ^ (bit_result ? POLY : 16'h0);
    
    // Pipeline stage 1: Input data registration and initial calculation
    always @(posedge clk) begin
        if (reset) begin
            crc_stage1 <= 16'h0000;
            data_stage1 <= 8'h00;
            data_valid_stage1 <= 1'b0;
            calc_done_stage1 <= 1'b0;
        end else begin
            data_stage1 <= data;
            data_valid_stage1 <= data_valid;
            calc_done_stage1 <= calc_done;
            
            if (data_valid) begin
                crc_stage1 <= crc_next;
            end
        end
    end
    
    // Pipeline stage 2: CRC processing
    always @(posedge clk) begin
        if (reset) begin
            crc_stage2 <= 16'h0000;
            calc_done_stage2 <= 1'b0;
        end else begin
            calc_done_stage2 <= calc_done_stage1;
            crc_stage2 <= data_valid_stage1 ? crc_stage1 : crc_stage2;
        end
    end
    
    // Pipeline stage 3: Prepare for final XOR
    always @(posedge clk) begin
        if (reset) begin
            crc_stage3 <= 16'h0000;
            calc_done_stage3 <= 1'b0;
        end else begin
            crc_stage3 <= crc_stage2;
            calc_done_stage3 <= calc_done_stage2;
        end
    end
    
    // Output stage with registered output
    always @(posedge clk) begin
        if (reset) begin
            crc_out <= 16'h0000;
        end else if (calc_done_stage3) begin
            crc_out <= crc_stage3 ^ FINAL_XOR;
        end
    end
endmodule