//SystemVerilog
module circular_buffer_pipeline #(
    parameter DW = 16,
    parameter DEPTH = 8
)(
    input clk,
    input rst,
    input push,
    input pop,
    input [DW-1:0] din,
    output [DW-1:0] dout,
    output full,
    output empty,
    output valid_out
);

reg [DW-1:0] buffer [0:DEPTH-1];
reg [3:0] wptr, rptr;
reg [3:0] wptr_stage1;
reg [3:0] rptr_stage1;
reg [DW-1:0] dout_reg;
reg valid_out_reg;
wire [3:0] wptr_next = wptr + 1;
wire [3:0] rptr_next = rptr + 1;

// 提前计算读取数据
wire [DW-1:0] read_data = buffer[rptr[2:0]];
wire [DW-1:0] read_data_next = buffer[rptr_next[2:0]];

// 组合逻辑信号检测
wire will_read = pop && !empty;
wire will_write = push && !full;

// 状态信号 - 直接输出组合逻辑
assign full = (wptr[2:0] == rptr[2:0]) && (wptr[3] ^ rptr[3]);
assign empty = (wptr == rptr);
assign dout = will_read ? read_data_next : dout_reg;
assign valid_out = valid_out_reg;

always @(posedge clk) begin
    if (rst) begin
        wptr <= 0;
        rptr <= 0;
        wptr_stage1 <= 0;
        rptr_stage1 <= 0;
        valid_out_reg <= 0;
        dout_reg <= 0;
    end else begin
        // 存储逻辑
        if (will_write) begin
            buffer[wptr[2:0]] <= din;
            wptr_stage1 <= wptr_next;
        end else begin
            wptr_stage1 <= wptr;
        end
        
        // 读取逻辑 - 优化时序
        if (will_read) begin
            rptr_stage1 <= rptr_next;
            valid_out_reg <= 1;
            dout_reg <= read_data_next;
        end else begin
            rptr_stage1 <= rptr;
            valid_out_reg <= 0;
            dout_reg <= read_data;
        end

        // 更新指针
        wptr <= wptr_stage1;
        rptr <= rptr_stage1;
    end
end

endmodule