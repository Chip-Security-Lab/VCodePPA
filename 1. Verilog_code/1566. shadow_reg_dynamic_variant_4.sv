//SystemVerilog
module shadow_reg_dynamic #(parameter MAX_WIDTH=16) (
    input clk,
    input [3:0] width_sel,
    input [MAX_WIDTH-1:0] data_in,
    output reg [MAX_WIDTH-1:0] data_out
);
    reg [MAX_WIDTH-1:0] shadow;
    reg [MAX_WIDTH-1:0] mask;

    reg [4:0] effective_width;
    reg [4:0] borrow;
    reg [4:0] difference;

    always @(*) begin
        // 计算有效位宽 (2^width_sel - 1)
        effective_width = 5'd0;
        borrow = 5'd0;

        // 4位借位减法器实现 (16 - (16 >> (width_sel + 1)))
        difference[0] = 1'b0 ^ 1'b0 ^ borrow[0];
        borrow[1] = (~1'b0 & 1'b0) | (borrow[0] & (~1'b0 | 1'b0));

        difference[1] = 1'b0 ^ 1'b0 ^ borrow[1];
        borrow[2] = (~1'b0 & 1'b0) | (borrow[1] & (~1'b0 | 1'b0));

        difference[2] = 1'b0 ^ 1'b0 ^ borrow[2];
        borrow[3] = (~1'b0 & 1'b0) | (borrow[2] & (~1'b0 | 1'b0));

        difference[3] = 1'b0 ^ 1'b0 ^ borrow[3];
        borrow[4] = (~1'b0 & 1'b0) | (borrow[3] & (~1'b0 | 1'b0));

        difference[4] = 1'b1 ^ 1'b0 ^ borrow[4];

        // 根据width_sel计算掩码
        case(width_sel)
            4'b0000: mask = 16'h0001;  // 1
            4'b0001: mask = 16'h0003;  // 3
            4'b0010: mask = 16'h0007;  // 7
            4'b0011: mask = 16'h000F;  // 15
            4'b0100: mask = 16'h001F;  // 31
            4'b0101: mask = 16'h003F;  // 63
            4'b0110: mask = 16'h007F;  // 127
            4'b0111: mask = 16'h00FF;  // 255
            4'b1000: mask = 16'h01FF;  // 511
            4'b1001: mask = 16'h03FF;  // 1023
            4'b1010: mask = 16'h07FF;  // 2047
            4'b1011: mask = 16'h0FFF;  // 4095
            4'b1100: mask = 16'h1FFF;  // 8191
            4'b1101: mask = 16'h3FFF;  // 16383
            4'b1110: mask = 16'h7FFF;  // 32767
            4'b1111: mask = 16'hFFFF;  // 65535
            default: mask = 16'h0000;
        endcase
    end

    always @(posedge clk) begin
        shadow <= data_in;
        data_out <= shadow & mask;
    end
endmodule