//SystemVerilog
module hybrid_regfile #(
    parameter TRIGGER_DEPTH = 8,
    parameter RAM_DEPTH = 24
)(
    input clk,
    input wr_en,
    input [7:0] addr,
    input [31:0] din,
    output reg [31:0] dout
);

// 低地址使用触发器
reg [31:0] trigger_bank [0:TRIGGER_DEPTH-1];

// 高地址使用RAM（行为级模型）
reg [31:0] ram_bank [TRIGGER_DEPTH:TRIGGER_DEPTH+RAM_DEPTH-1];

// 地址比较流水线寄存器
reg addr_lt_trigger_depth;
reg addr_lt_total_depth;

// 数据流水线寄存器
reg [31:0] trigger_data;
reg [31:0] ram_data;

// 地址比较流水线
always @(posedge clk) begin
    addr_lt_trigger_depth <= (addr < TRIGGER_DEPTH);
    addr_lt_total_depth <= (addr < (TRIGGER_DEPTH + RAM_DEPTH));
end

// 写操作流水线
always @(posedge clk) begin
    if (wr_en) begin
        if (addr_lt_trigger_depth)
            trigger_bank[addr] <= din;
        else if (addr_lt_total_depth)
            ram_bank[addr] <= din;
    end
end

// 读操作流水线
always @(posedge clk) begin
    trigger_data <= trigger_bank[addr];
    ram_data <= ram_bank[addr];
end

// 输出选择流水线
always @(posedge clk) begin
    dout <= addr_lt_trigger_depth ? trigger_data : ram_data;
end

endmodule