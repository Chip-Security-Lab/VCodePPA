//SystemVerilog
// 地址范围比较子模块
module addr_range_compare #(
    parameter MIN = 8'h20,
    parameter MAX = 8'h3F
)(
    input [7:0] addr,
    output reg in_range
);
    always @(*) begin
        in_range = (addr >= MIN) && (addr <= MAX);
    end
endmodule

// 地址归一化子模块
module addr_normalize #(
    parameter MIN = 8'h20,
    parameter MAX = 8'h3F
)(
    input [7:0] addr,
    output [7:0] normalized_addr
);
    assign normalized_addr = addr - MIN;
endmodule

// 顶层解码器模块
module decoder_range #(
    parameter MIN = 8'h20,
    parameter MAX = 8'h3F
)(
    input [7:0] addr,
    output active
);
    wire in_range;
    wire [7:0] normalized_addr;
    
    addr_range_compare #(
        .MIN(MIN),
        .MAX(MAX)
    ) range_comp (
        .addr(addr),
        .in_range(in_range)
    );
    
    addr_normalize #(
        .MIN(MIN),
        .MAX(MAX)
    ) norm (
        .addr(addr),
        .normalized_addr(normalized_addr)
    );
    
    assign active = in_range;
endmodule