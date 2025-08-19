//SystemVerilog
`timescale 1ns/1ps
module crc8_generator #(
    parameter POLY = 8'h07 // CRC-8多项式 x^8 + x^2 + x + 1
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        enable,
    input  wire        data_in,
    input  wire        init,
    output wire [7:0]  crc_out
);

    // Stage 1 pipeline registers
    reg [7:0] crc_shift_stage1;
    reg       feedback_bit_stage1;
    reg       enable_stage1;
    reg       init_stage1;

    // Stage 2 pipeline register
    reg [7:0] crc_reg;

    // Internal wire for crc_shift input
    wire [7:0] crc_shift_input;
    assign crc_shift_input = (init) ? 8'h00 : 
                             (enable) ? {crc_reg[6:0], 1'b0} : crc_reg;

    // Internal wire for feedback bit input
    wire feedback_bit_input;
    assign feedback_bit_input = (enable) ? crc_reg[7] ^ data_in : 1'b0;

    // Stage 1: Register crc_shift_stage1
    always @(posedge clk or posedge rst) begin
        if (rst)
            crc_shift_stage1 <= 8'h00;
        else
            crc_shift_stage1 <= crc_shift_input;
    end

    // Stage 1: Register feedback_bit_stage1
    always @(posedge clk or posedge rst) begin
        if (rst)
            feedback_bit_stage1 <= 1'b0;
        else
            feedback_bit_stage1 <= feedback_bit_input;
    end

    // Stage 1: Register enable_stage1
    always @(posedge clk or posedge rst) begin
        if (rst)
            enable_stage1 <= 1'b0;
        else
            enable_stage1 <= enable;
    end

    // Stage 1: Register init_stage1
    always @(posedge clk or posedge rst) begin
        if (rst)
            init_stage1 <= 1'b0;
        else
            init_stage1 <= init;
    end

    // Stage 2: Register crc_reg
    always @(posedge clk or posedge rst) begin
        if (rst)
            crc_reg <= 8'h00;
        else if (init_stage1)
            crc_reg <= 8'h00;
        else if (enable_stage1) begin
            if (feedback_bit_stage1)
                crc_reg <= crc_shift_stage1 ^ POLY;
            else
                crc_reg <= crc_shift_stage1;
        end
    end

    assign crc_out = crc_reg;

endmodule