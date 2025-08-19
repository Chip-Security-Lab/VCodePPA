//SystemVerilog
module decoder_crc #(AW=8, DW=8) (
    input [AW-1:0] addr,
    input [DW-1:0] data,
    output select
);

wire [7:0] crc_result;
wire addr_match;

crc_calculator #(.WIDTH(8)) u_crc_calc (
    .addr(addr),
    .data(data),
    .crc(crc_result)
);

addr_decoder #(.AW(8)) u_addr_dec (
    .addr(addr),
    .match(addr_match)
);

final_selector u_selector (
    .addr_match(addr_match),
    .crc(crc_result),
    .select(select)
);

endmodule

module crc_calculator #(parameter WIDTH=8) (
    input [WIDTH-1:0] addr,
    input [WIDTH-1:0] data,
    output [WIDTH-1:0] crc
);

wire [7:0] borrow;
wire [7:0] diff;

// Generate borrow signals
assign borrow[0] = ~addr[0] & data[0];
assign borrow[1] = (~addr[1] & data[1]) | (~addr[1] & borrow[0]) | (data[1] & borrow[0]);
assign borrow[2] = (~addr[2] & data[2]) | (~addr[2] & borrow[1]) | (data[2] & borrow[1]);
assign borrow[3] = (~addr[3] & data[3]) | (~addr[3] & borrow[2]) | (data[3] & borrow[2]);
assign borrow[4] = (~addr[4] & data[4]) | (~addr[4] & borrow[3]) | (data[4] & borrow[3]);
assign borrow[5] = (~addr[5] & data[5]) | (~addr[5] & borrow[4]) | (data[5] & borrow[4]);
assign borrow[6] = (~addr[6] & data[6]) | (~addr[6] & borrow[5]) | (data[6] & borrow[5]);
assign borrow[7] = (~addr[7] & data[7]) | (~addr[7] & borrow[6]) | (data[7] & borrow[6]);

// Calculate difference
assign diff[0] = addr[0] ^ data[0];
assign diff[1] = addr[1] ^ data[1] ^ borrow[0];
assign diff[2] = addr[2] ^ data[2] ^ borrow[1];
assign diff[3] = addr[3] ^ data[3] ^ borrow[2];
assign diff[4] = addr[4] ^ data[4] ^ borrow[3];
assign diff[5] = addr[5] ^ data[5] ^ borrow[4];
assign diff[6] = addr[6] ^ data[6] ^ borrow[5];
assign diff[7] = addr[7] ^ data[7] ^ borrow[6];

assign crc = diff;

endmodule

module addr_decoder #(parameter AW=8) (
    input [AW-1:0] addr,
    output match
);

assign match = (addr[7:4] == 4'b1010);

endmodule

module final_selector (
    input addr_match,
    input [7:0] crc,
    output reg select
);

always @* begin
    select = addr_match && (crc == 8'h55);
end

endmodule