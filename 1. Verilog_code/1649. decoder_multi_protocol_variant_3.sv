//SystemVerilog
module decoder_multi_protocol (
    input [1:0] mode,
    input [15:0] addr,
    output reg [7:0] select
);

// 实例化补码计算模块
wire [15:0] addr_comp;
complement_calculator comp_calc (
    .addr(addr),
    .addr_comp(addr_comp)
);

// 实例化乘法器模块
wire [15:0] sum_products;
baugh_wooley_multiplier multiplier (
    .addr(addr),
    .addr_comp(addr_comp),
    .sum_products(sum_products)
);

// 实例化协议解码模块
protocol_decoder decoder (
    .mode(mode),
    .sum_products(sum_products),
    .select(select)
);

endmodule

module complement_calculator (
    input [15:0] addr,
    output [15:0] addr_comp
);

wire [15:0] addr_comp_neg;
assign addr_comp = ~addr + 1'b1;
assign addr_comp_neg = ~addr_comp;

endmodule

module baugh_wooley_multiplier (
    input [15:0] addr,
    input [15:0] addr_comp,
    output [15:0] sum_products
);

wire [15:0] partial_products [15:0];

genvar i;
generate
    for (i = 0; i < 16; i = i + 1) begin : gen_partial_products
        assign partial_products[i] = {16{addr[i]}} & addr_comp;
    end
endgenerate

assign sum_products = partial_products[0] + partial_products[1] + partial_products[2] + partial_products[3] +
                     partial_products[4] + partial_products[5] + partial_products[6] + partial_products[7] +
                     partial_products[8] + partial_products[9] + partial_products[10] + partial_products[11] +
                     partial_products[12] + partial_products[13] + partial_products[14] + partial_products[15];

endmodule

module protocol_decoder (
    input [1:0] mode,
    input [15:0] sum_products,
    output reg [7:0] select
);

always @* begin
    case(mode)
        2'b00: select = (sum_products[15:12] == 4'h1) ? 8'h01 : 8'h00;  // I2C模式
        2'b01: select = (sum_products[7:5] == 3'b101) ? 8'h02 : 8'h00;  // SPI模式
        2'b10: select = (sum_products[11:8] > 4'h7) ? 8'h04 : 8'h00;    // AXI模式
        default: select = 8'h00;
    endcase
end

endmodule