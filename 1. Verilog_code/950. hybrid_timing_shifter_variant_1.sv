//SystemVerilog
module hybrid_timing_shifter (
    input clk, rst_n,
    input en,
    input [7:0] din,
    input [2:0] shift,
    output [7:0] dout,
    input ready_in,
    output ready_out,
    output valid_out
);

// 流水线寄存器和控制信号
reg [7:0] data_stage1, data_stage2;
reg [2:0] shift_stage1, shift_stage2;
reg valid_stage1, valid_stage2;
reg ready_stage2;

// 流水线第一级 - 输入寄存器
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_stage1 <= 8'b0;
        shift_stage1 <= 3'b0;
        valid_stage1 <= 1'b0;
    end else if (ready_stage2) begin
        if (en && ready_in) begin
            data_stage1 <= din;
            shift_stage1 <= shift;
            valid_stage1 <= 1'b1;
        end else begin
            valid_stage1 <= 1'b0;
        end
    end
end

// 流水线第二级 - 移位运算寄存器
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_stage2 <= 8'b0;
        shift_stage2 <= 3'b0;
        valid_stage2 <= 1'b0;
    end else if (ready_out) begin
        data_stage2 <= data_stage1 << shift_stage1;
        shift_stage2 <= shift_stage1;
        valid_stage2 <= valid_stage1;
    end
end

// 反压控制逻辑
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ready_stage2 <= 1'b1;
    end else begin
        ready_stage2 <= ready_out || !valid_stage2;
    end
end

// 输出赋值
assign dout = data_stage2;
assign valid_out = valid_stage2;
assign ready_out = 1'b1; // 此处可以连接到下游模块的ready信号

endmodule