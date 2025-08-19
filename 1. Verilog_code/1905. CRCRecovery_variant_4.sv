//SystemVerilog
module CRCRecovery #(parameter WIDTH=8) (
    input wire clk,
    input wire rst,
    input wire [WIDTH+3:0] coded_in,
    input wire valid_in,
    output wire valid_out,
    output wire [WIDTH-1:0] data_out,
    output wire crc_error
);
    // Stage 1 - Calculate CRC
    reg [3:0] calc_crc_stage1;
    reg [WIDTH-1:0] data_stage1;
    reg valid_stage1;
    
    // Stage 2 - CRC Error Detection
    reg crc_error_stage2;
    reg [WIDTH-1:0] data_stage2;
    reg valid_stage2;
    
    // Pipeline Stage 1: CRC Calculation
    always @(posedge clk) begin
        if (rst) begin
            calc_crc_stage1 <= 4'b0;
            data_stage1 <= {WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end
        else if (valid_in) begin
            calc_crc_stage1 <= coded_in[WIDTH+3:WIDTH] ^ coded_in[WIDTH-1:0];
            data_stage1 <= coded_in[WIDTH-1:0];
            valid_stage1 <= 1'b1;
        end
        else begin
            valid_stage1 <= 1'b0;
        end
    end
    
    // Pipeline Stage 2: Error Detection and Data Selection
    always @(posedge clk) begin
        if (rst) begin
            crc_error_stage2 <= 1'b0;
            data_stage2 <= {WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end
        else if (valid_stage1 && |calc_crc_stage1) begin
            crc_error_stage2 <= 1'b1;
            data_stage2 <= {WIDTH{1'b1}};
            valid_stage2 <= 1'b1;
        end
        else if (valid_stage1) begin
            crc_error_stage2 <= 1'b0;
            data_stage2 <= data_stage1;
            valid_stage2 <= 1'b1;
        end
        else begin
            valid_stage2 <= 1'b0;
        end
    end
    
    // Output assignments
    assign data_out = data_stage2;
    assign crc_error = crc_error_stage2;
    assign valid_out = valid_stage2;
    
endmodule