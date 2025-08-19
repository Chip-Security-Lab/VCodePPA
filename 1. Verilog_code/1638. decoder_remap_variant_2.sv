//SystemVerilog
module decoder_remap (
    input clk,
    input [7:0] base_addr,
    input [7:0] addr,
    output reg select
);

// 地址映射计算模块
wire [7:0] mapped_addr;
addr_mapper #(
    .ADDR_WIDTH(8)
) addr_mapper_inst (
    .clk(clk),
    .base_addr(base_addr),
    .addr(addr),
    .mapped_addr(mapped_addr)
);

// 地址范围检测模块
wire in_range;
range_checker #(
    .ADDR_WIDTH(8),
    .THRESHOLD(8'h10)
) range_checker_inst (
    .clk(clk),
    .addr(mapped_addr),
    .in_range(in_range)
);

// 选择信号生成模块
select_generator select_gen_inst (
    .clk(clk),
    .in_range(in_range),
    .select(select)
);

endmodule

module addr_mapper #(
    parameter ADDR_WIDTH = 8
) (
    input clk,
    input [ADDR_WIDTH-1:0] base_addr,
    input [ADDR_WIDTH-1:0] addr,
    output reg [ADDR_WIDTH-1:0] mapped_addr
);
always @(posedge clk) begin
    mapped_addr <= addr - base_addr;
end
endmodule

module range_checker #(
    parameter ADDR_WIDTH = 8,
    parameter THRESHOLD = 8'h10
) (
    input clk,
    input [ADDR_WIDTH-1:0] addr,
    output reg in_range
);
always @(posedge clk) begin
    in_range <= (addr < THRESHOLD);
end
endmodule

module select_generator (
    input clk,
    input in_range,
    output reg select
);
always @(posedge clk) begin
    select <= in_range;
end
endmodule