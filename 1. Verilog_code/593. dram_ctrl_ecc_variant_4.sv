//SystemVerilog
module dram_ctrl_ecc #(
    parameter DATA_WIDTH = 64,
    parameter ECC_WIDTH = 8
)(
    input clk,
    input rst_n,
    input [DATA_WIDTH-1:0] data_in,
    input data_valid,
    output [DATA_WIDTH-1:0] data_out,
    output [ECC_WIDTH-1:0] ecc_syndrome,
    output data_out_valid
);

    // Pipeline stage 1: Data input and ECC calculation
    reg [DATA_WIDTH-1:0] data_stage1;
    reg [ECC_WIDTH-1:0] ecc_stage1;
    reg valid_stage1;

    // Pipeline stage 2: ECC syndrome calculation
    reg [DATA_WIDTH-1:0] data_stage2;
    reg [ECC_WIDTH-1:0] ecc_stage2;
    reg [ECC_WIDTH-1:0] syndrome_stage2;
    reg valid_stage2;

    // ECC calculation function
    function [ECC_WIDTH-1:0] calculate_ecc;
        input [DATA_WIDTH-1:0] data;
        reg [DATA_WIDTH-1:0] temp_data;
        reg [ECC_WIDTH-1:0] ecc_result;
        begin
            temp_data = data;
            ecc_result = 0;
            for (integer i = 0; i < ECC_WIDTH; i = i + 1) begin
                ecc_result[i] = ^(temp_data & (64'h1 << i));
            end
            calculate_ecc = ecc_result;
        end
    endfunction

    // Stage 1 pipeline register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= 0;
            ecc_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            data_stage1 <= data_in;
            ecc_stage1 <= calculate_ecc(data_in);
            valid_stage1 <= data_valid;
        end
    end

    // Stage 2 pipeline register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2 <= 0;
            ecc_stage2 <= 0;
            syndrome_stage2 <= 0;
            valid_stage2 <= 0;
        end else begin
            data_stage2 <= data_stage1;
            ecc_stage2 <= ecc_stage1;
            syndrome_stage2 <= ecc_stage1 ^ calculate_ecc(data_stage1);
            valid_stage2 <= valid_stage1;
        end
    end

    // Output assignments
    assign data_out = data_stage2;
    assign ecc_syndrome = syndrome_stage2;
    assign data_out_valid = valid_stage2;

endmodule