//SystemVerilog
// 顶层模块
module decoder_crc #(AW=8, DW=8) (
    input [AW-1:0] addr,
    input [DW-1:0] data,
    output reg select
);

wire [7:0] crc;

// 实例化减法器子模块
subtractor #(.WIDTH(8)) sub_inst (
    .a(addr),
    .b(data),
    .diff(crc)
);

// 实例化解码器子模块
decoder #(.WIDTH(8)) dec_inst (
    .addr(addr),
    .crc(crc),
    .select(select)
);

endmodule

// 减法器子模块
module subtractor #(WIDTH=8) (
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] diff
);

wire [WIDTH-1:0] borrow;

// 先行借位减法器实现
assign borrow[0] = 1'b0;
assign diff[0] = a[0] ^ b[0] ^ borrow[0];
assign borrow[1] = (~a[0] & b[0]) | (~a[0] & borrow[0]) | (b[0] & borrow[0]);

assign diff[1] = a[1] ^ b[1] ^ borrow[1];
assign borrow[2] = (~a[1] & b[1]) | (~a[1] & borrow[1]) | (b[1] & borrow[1]);

assign diff[2] = a[2] ^ b[2] ^ borrow[2];
assign borrow[3] = (~a[2] & b[2]) | (~a[2] & borrow[2]) | (b[2] & borrow[2]);

assign diff[3] = a[3] ^ b[3] ^ borrow[3];
assign borrow[4] = (~a[3] & b[3]) | (~a[3] & borrow[3]) | (b[3] & borrow[3]);

assign diff[4] = a[4] ^ b[4] ^ borrow[4];
assign borrow[5] = (~a[4] & b[4]) | (~a[4] & borrow[4]) | (b[4] & borrow[4]);

assign diff[5] = a[5] ^ b[5] ^ borrow[5];
assign borrow[6] = (~a[5] & b[5]) | (~a[5] & borrow[5]) | (b[5] & borrow[5]);

assign diff[6] = a[6] ^ b[6] ^ borrow[6];
assign borrow[7] = (~a[6] & b[6]) | (~a[6] & borrow[6]) | (b[6] & borrow[6]);

assign diff[7] = a[7] ^ b[7] ^ borrow[7];

endmodule

// 解码器子模块
module decoder #(WIDTH=8) (
    input [WIDTH-1:0] addr,
    input [WIDTH-1:0] crc,
    output reg select
);

always @* begin
    select = (addr[7:4] == 4'b1010) && (crc == 8'h55);
end

endmodule