//SystemVerilog
module crc_converter #(parameter DW=8) (
    input clk,
    input en,
    input [DW-1:0] data,
    output [DW-1:0] crc
);
    reg [DW-1:0] crc_reg;
    reg [DW-1:0] data_reg;
    reg en_reg;

    always @(posedge clk) begin
        data_reg <= data;
        en_reg <= en;
    end

    // 7-bit subtractor LUT for (a - b)
    function [6:0] lut_sub7;
        input [6:0] a, b;
        reg [6:0] sub_lut [0:127][0:127];
        integer i, j;
        begin
            for (i = 0; i < 128; i = i + 1)
                for (j = 0; j < 128; j = j + 1)
                    sub_lut[i][j] = i - j;
            lut_sub7 = sub_lut[a][b];
        end
    endfunction

    // 7-bit adder LUT for (a + b)
    function [6:0] lut_add7;
        input [6:0] a, b;
        reg [6:0] add_lut [0:127][0:127];
        integer i, j;
        begin
            for (i = 0; i < 128; i = i + 1)
                for (j = 0; j < 128; j = j + 1)
                    add_lut[i][j] = i + j;
            lut_add7 = add_lut[a][b];
        end
    endfunction

    // Pipeline stage 1: Extract crc_reg_low and crc_reg_high
    reg [6:0] crc_reg_low_stage1;
    reg       crc_reg_high_stage1;

    always @(posedge clk) begin
        crc_reg_low_stage1  <= crc_reg[6:0];
        crc_reg_high_stage1 <= crc_reg[7];
    end

    // Pipeline stage 2: shifted_crc_low calculation
    reg [6:0] shifted_crc_low_stage2;
    reg       crc_reg_high_stage2;
    always @(posedge clk) begin
        shifted_crc_low_stage2  <= {crc_reg_low_stage1[5:0], 1'b0};
        crc_reg_high_stage2     <= crc_reg_high_stage1;
    end

    // Pipeline stage 3: LUT subtraction
    reg [6:0] lut_result_stage3;
    reg       crc_reg_high_stage3;
    always @(posedge clk) begin
        lut_result_stage3      <= lut_sub7(shifted_crc_low_stage2, (crc_reg_high_stage2 ? 7'h07 : 7'h00));
        crc_reg_high_stage3    <= crc_reg_high_stage2;
    end

    // Pipeline stage 4: next_crc calculation
    reg [DW-1:0] next_crc_stage4;
    always @(posedge clk) begin
        next_crc_stage4 <= {lut_result_stage3, 1'b0} ^ (crc_reg_high_stage3 ? 8'h07 : 8'h00);
    end

    // Pipeline stage 5: crc_comb calculation with data_reg
    reg [DW-1:0] crc_comb_stage5;
    reg          en_reg_stage5;
    always @(posedge clk) begin
        crc_comb_stage5 <= next_crc_stage4 ^ data_reg;
        en_reg_stage5   <= en_reg;
    end

    // Pipeline stage 6: crc_reg update
    always @(posedge clk) begin
        if(en_reg_stage5)
            crc_reg <= crc_comb_stage5;
        else
            crc_reg <= 8'hFF;
    end

    assign crc = crc_reg;

endmodule