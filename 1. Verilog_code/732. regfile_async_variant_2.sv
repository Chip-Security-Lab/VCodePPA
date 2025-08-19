//SystemVerilog
module regfile_pipelined #(
    parameter WORD_SIZE = 16,
    parameter ADDR_BITS = 4,
    parameter NUM_WORDS = 16
)(
    input clk,
    input rst_n,
    input valid_in,
    input write_en,
    input [ADDR_BITS-1:0] raddr,
    input [ADDR_BITS-1:0] waddr,
    input [WORD_SIZE-1:0] wdata,
    output [WORD_SIZE-1:0] rdata,
    output valid_out
);

// 存储器数组
reg [WORD_SIZE-1:0] storage [0:NUM_WORDS-1];

// 流水线寄存器 - 第一级
reg [ADDR_BITS-1:0] raddr_stage1;
reg valid_stage1;

// 流水线寄存器 - 第二级
reg [WORD_SIZE-1:0] rdata_stage2;
reg valid_stage2;

// 组合逻辑 - 读取数据
wire [WORD_SIZE-1:0] read_data;
assign read_data = storage[raddr_stage1];

// 时序逻辑 - 写入操作
always @(posedge clk) begin
    if (write_en) begin
        storage[waddr] <= wdata;
    end
end

// 时序逻辑 - 第一级流水线
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        raddr_stage1 <= {ADDR_BITS{1'b0}};
        valid_stage1 <= 1'b0;
    end else begin
        raddr_stage1 <= raddr;
        valid_stage1 <= valid_in;
    end
end

// 时序逻辑 - 第二级流水线
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rdata_stage2 <= {WORD_SIZE{1'b0}};
        valid_stage2 <= 1'b0;
    end else begin
        rdata_stage2 <= read_data;
        valid_stage2 <= valid_stage1;
    end
end

// 组合逻辑 - 输出
assign rdata = rdata_stage2;
assign valid_out = valid_stage2;

endmodule