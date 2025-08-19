//SystemVerilog
module CrcCheckBridge #(
    parameter DATA_W = 32,
    parameter CRC_W = 8
)(
    input clk, rst_n,
    input [DATA_W-1:0] data_in,
    input data_valid,
    output reg [DATA_W-1:0] data_out,
    output reg crc_error
);
    // Pipeline stage 1 signals
    reg [DATA_W-1:0] data_stage1;
    reg valid_stage1;
    reg [CRC_W-1:0] crc_stage1;
    
    // Pipeline stage 2 signals
    reg [DATA_W-1:0] data_stage2;
    reg valid_stage2;
    reg [CRC_W-1:0] crc_stage2;
    
    // Pipeline stage 3 signals
    reg [DATA_W-1:0] data_stage3;
    reg valid_stage3;
    reg [CRC_W-1:0] crc_stage3;
    
    // Lookup table for CRC calculation
    reg [CRC_W-1:0] crc_lut [0:255];
    integer i;
    
    // Initialize lookup table
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            crc_lut[i] = (i << 1) ^ (i & 8'h80 ? 8'h07 : 8'h00);
        end
    end
    
    // Stage 1: Input registration and initial CRC calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= {DATA_W{1'b0}};
            valid_stage1 <= 1'b0;
            crc_stage1 <= {CRC_W{1'b0}};
        end else begin
            data_stage1 <= data_in;
            valid_stage1 <= data_valid;
            crc_stage1 <= crc_lut[data_in[7:0]];
        end
    end
    
    // Stage 2: Intermediate CRC calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2 <= {DATA_W{1'b0}};
            valid_stage2 <= 1'b0;
            crc_stage2 <= {CRC_W{1'b0}};
        end else begin
            data_stage2 <= data_stage1;
            valid_stage2 <= valid_stage1;
            crc_stage2 <= crc_lut[data_stage1[15:8] ^ crc_stage1];
        end
    end
    
    // Stage 3: Final CRC calculation and error detection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage3 <= {DATA_W{1'b0}};
            valid_stage3 <= 1'b0;
            crc_stage3 <= {CRC_W{1'b0}};
            data_out <= {DATA_W{1'b0}};
            crc_error <= 1'b0;
        end else begin
            data_stage3 <= data_stage2;
            valid_stage3 <= valid_stage2;
            crc_stage3 <= crc_lut[data_stage2[23:16] ^ crc_stage2];
            
            if (valid_stage3) begin
                data_out <= data_stage3;
                crc_error <= (crc_lut[data_stage3[31:24] ^ crc_stage3] != 0);
            end else begin
                crc_error <= 1'b0;
            end
        end
    end
endmodule