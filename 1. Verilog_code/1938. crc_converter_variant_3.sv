//SystemVerilog
module crc_converter #(parameter DW=8) (
    input wire clk,
    input wire en,
    input wire [DW-1:0] data,
    output wire [DW-1:0] crc
);
    reg [DW-1:0] crc_reg;
    reg [DW-1:0] data_reg;
    reg en_reg;

    // First stage buffer for crc_reg to drive next_crc_pre
    reg [DW-1:0] crc_reg_buf1;

    // Second stage buffer for crc_reg to drive output
    reg [DW-1:0] crc_reg_buf2;

    // Register inputs and enable before CRC computation
    always @(posedge clk) begin
        data_reg <= data;
        en_reg <= en;
    end

    // Buffer stage 1: crc_reg to crc_reg_buf1
    always @(posedge clk) begin
        crc_reg_buf1 <= crc_reg;
    end

    // Buffer stage 2: crc_reg to crc_reg_buf2 (for output)
    always @(posedge clk) begin
        crc_reg_buf2 <= crc_reg;
    end

    wire [DW-1:0] next_crc_pre = {crc_reg_buf1[6:0], 1'b0} ^ (crc_reg_buf1[7] ? 8'h07 : 8'h00);
    wire [DW-1:0] next_crc = next_crc_pre ^ data_reg;

    always @(posedge clk) begin
        if(en_reg)
            crc_reg <= next_crc;
        else
            crc_reg <= 8'hFF;
    end

    assign crc = crc_reg_buf2;

endmodule