//SystemVerilog
module basic_crc8(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    input wire data_valid,
    output reg [7:0] crc_out
);
    parameter POLY = 8'hD5; // x^8 + x^7 + x^6 + x^4 + x^2 + 1
    
    // Stage 1 registers
    reg [7:0] data_in_stage1;
    reg [7:0] crc_stage1;
    reg valid_stage1;
    
    // Stage 2 registers
    reg [7:0] xor_result_stage2;
    reg valid_stage2;
    
    // Stage 1: Input registration
    always @(posedge clk) begin
        if (!rst_n) begin
            data_in_stage1 <= 8'h00;
            valid_stage1 <= 1'b0;
        end else begin
            data_in_stage1 <= data_in;
            valid_stage1 <= data_valid;
        end
    end
    
    // Stage 1: CRC feedback registration
    always @(posedge clk) begin
        if (!rst_n) begin
            crc_stage1 <= 8'h00;
        end else begin
            crc_stage1 <= crc_out;
        end
    end
    
    // Stage 2: Polynomial multiplication
    reg [7:0] poly_mult;
    always @(posedge clk) begin
        if (!rst_n) begin
            poly_mult <= 8'h00;
        end else begin
            poly_mult <= {8{crc_stage1[7]}} & POLY;
        end
    end
    
    // Stage 2: CRC shift and XOR computation
    always @(posedge clk) begin
        if (!rst_n) begin
            xor_result_stage2 <= 8'h00;
            valid_stage2 <= 1'b0;
        end else begin
            if (valid_stage1) begin
                xor_result_stage2 <= {crc_stage1[6:0], 1'b0} ^ poly_mult ^ data_in_stage1;
            end
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Output registration
    always @(posedge clk) begin
        if (!rst_n) begin
            crc_out <= 8'h00;
        end else if (valid_stage2) begin
            crc_out <= xor_result_stage2;
        end
    end
    
endmodule