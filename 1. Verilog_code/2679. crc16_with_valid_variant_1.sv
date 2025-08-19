//SystemVerilog
module crc16_with_valid(
    input clk,
    input reset,
    input [7:0] data_in,
    input data_valid,
    output reg [15:0] crc,
    output reg crc_valid
);

    localparam POLY = 16'h1021;
    
    // Pipeline stage 1 registers
    reg [7:0] data_stage1;
    reg valid_stage1;
    reg [15:0] crc_stage1;
    
    // Pipeline stage 2 registers
    reg [15:0] crc_stage2;
    reg valid_stage2;
    
    // Pipeline stage 3 registers
    reg [15:0] crc_stage3;
    reg valid_stage3;
    
    // Buffer registers for high fanout signals
    reg [15:0] crc_buffer1;
    reg [15:0] crc_buffer2;
    reg [15:0] crc_buffer3;
    
    // Stage 1: Input and initial CRC calculation
    always @(posedge clk) begin
        if (reset) begin
            data_stage1 <= 8'h00;
            valid_stage1 <= 1'b0;
            crc_stage1 <= 16'hFFFF;
            crc_buffer1 <= 16'hFFFF;
        end else begin
            data_stage1 <= data_in;
            valid_stage1 <= data_valid;
            if (data_valid) begin
                crc_stage1 <= {crc_buffer1[14:0], 1'b0} ^ (crc_buffer1[15] ? POLY : 16'h0000);
            end else begin
                crc_stage1 <= crc_buffer1;
            end
            crc_buffer1 <= crc;
        end
    end
    
    // Stage 2: XOR with input data
    always @(posedge clk) begin
        if (reset) begin
            crc_stage2 <= 16'hFFFF;
            valid_stage2 <= 1'b0;
            crc_buffer2 <= 16'hFFFF;
        end else begin
            crc_stage2 <= crc_buffer2 ^ {8'h00, data_stage1};
            valid_stage2 <= valid_stage1;
            crc_buffer2 <= crc_stage1;
        end
    end
    
    // Stage 3: Final CRC value
    always @(posedge clk) begin
        if (reset) begin
            crc_stage3 <= 16'hFFFF;
            valid_stage3 <= 1'b0;
            crc_buffer3 <= 16'hFFFF;
        end else begin
            crc_stage3 <= crc_buffer3;
            valid_stage3 <= valid_stage2;
            crc_buffer3 <= crc_stage2;
        end
    end
    
    // Output assignment
    assign crc = crc_stage3;
    assign crc_valid = valid_stage3;

endmodule