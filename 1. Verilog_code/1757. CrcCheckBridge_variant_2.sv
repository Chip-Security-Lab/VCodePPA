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

    // Pipeline stage 1 registers
    reg [DATA_W-1:0] data_stage1;
    reg valid_stage1;
    reg [CRC_W-1:0] crc_stage1;
    
    // Pipeline stage 2 registers
    reg [DATA_W-1:0] data_stage2;
    reg valid_stage2;
    reg [CRC_W-1:0] crc_stage2;
    
    // Pipeline stage 3 registers
    reg [DATA_W-1:0] data_stage3;
    reg valid_stage3;
    reg [CRC_W-1:0] crc_stage3;

    // Stage 1: Data capture
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= 0;
        end else begin
            data_stage1 <= data_in;
        end
    end

    // Stage 1: Valid signal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage1 <= 0;
        end else begin
            valid_stage1 <= data_valid;
        end
    end

    // Stage 1: CRC calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_stage1 <= 0;
        end else if (data_valid) begin
            crc_stage1 <= ^{data_in, crc_stage3} << 1;
        end
    end

    // Stage 2: Data pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2 <= 0;
        end else begin
            data_stage2 <= data_stage1;
        end
    end

    // Stage 2: Valid pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage2 <= 0;
        end else begin
            valid_stage2 <= valid_stage1;
        end
    end

    // Stage 2: CRC pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_stage2 <= 0;
        end else begin
            crc_stage2 <= crc_stage1;
        end
    end

    // Stage 3: Data pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage3 <= 0;
        end else begin
            data_stage3 <= data_stage2;
        end
    end

    // Stage 3: Valid pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage3 <= 0;
        end else begin
            valid_stage3 <= valid_stage2;
        end
    end

    // Stage 3: CRC pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_stage3 <= 0;
        end else begin
            crc_stage3 <= crc_stage2;
        end
    end

    // Output: Data
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 0;
        end else begin
            data_out <= data_stage3;
        end
    end

    // Output: CRC error
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_error <= 0;
        end else begin
            crc_error <= (crc_stage3 != 0) & valid_stage3;
        end
    end

endmodule