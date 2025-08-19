//SystemVerilog
module timeout_buf #(parameter DW=8, TIMEOUT=100) (
    input clk, rst_n,
    input wr_en, rd_en,
    input [DW-1:0] din,
    output [DW-1:0] dout,
    output valid,
    // 流水线控制信号
    input ready_in,
    output ready_out,
    output valid_out
);
    // 流水线阶段寄存器
    reg [DW-1:0] data_stage1, data_stage2, data_stage3;
    reg [15:0] timer_stage1, timer_stage2, timer_stage3;
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // 流水线控制信号
    reg ready_stage2, ready_stage3;
    wire stall_stage1, stall_stage2, stall_stage3;
    
    // 流水线计算中间结果
    wire [15:0] timer_next_stage1, timer_next_stage2;
    wire timer_overflow_stage1, timer_overflow_stage2;
    
    // 第一级流水线: 接收数据和计时器更新
    assign timer_next_stage1 = (wr_en) ? 16'b0 : (valid_stage1 ? timer_stage1 + 1'b1 : timer_stage1);
    assign timer_overflow_stage1 = (timer_next_stage1 >= TIMEOUT);
    
    // 流水线级联控制
    assign stall_stage1 = ~ready_stage2;
    assign stall_stage2 = ~ready_stage3;
    assign stall_stage3 = ~ready_out;
    
    // 第一级流水线寄存器
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            valid_stage1 <= 1'b0;
            timer_stage1 <= 16'b0;
            data_stage1 <= {DW{1'b0}};
        end else if (!stall_stage1) begin
            if(wr_en) begin
                data_stage1 <= din;
                valid_stage1 <= 1'b1;
                timer_stage1 <= 16'b0;
            end else begin
                valid_stage1 <= valid_stage1 & ~timer_overflow_stage1 & ~(rd_en & valid_stage1);
                timer_stage1 <= timer_next_stage1;
            end
        end
    end
    
    // 第二级流水线: 计时器溢出检测
    assign timer_next_stage2 = timer_stage2 + 1'b1;
    assign timer_overflow_stage2 = (timer_next_stage2 >= TIMEOUT);
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            valid_stage2 <= 1'b0;
            timer_stage2 <= 16'b0;
            data_stage2 <= {DW{1'b0}};
            ready_stage2 <= 1'b1;
        end else if (!stall_stage2) begin
            valid_stage2 <= valid_stage1;
            timer_stage2 <= timer_stage1;
            data_stage2 <= data_stage1;
            ready_stage2 <= ready_stage3;
        end else begin
            ready_stage2 <= ready_stage3;
        end
    end
    
    // 第三级流水线: 输出结果准备
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            valid_stage3 <= 1'b0;
            timer_stage3 <= 16'b0;
            data_stage3 <= {DW{1'b0}};
            ready_stage3 <= 1'b1;
        end else if (!stall_stage3) begin
            valid_stage3 <= valid_stage2 & ~timer_overflow_stage2 & ~(rd_en & valid_stage2);
            timer_stage3 <= timer_stage2;
            data_stage3 <= data_stage2;
            ready_stage3 <= ready_out;
        end else begin
            ready_stage3 <= ready_out;
        end
    end
    
    // 输出赋值
    assign dout = data_stage3;
    assign valid = valid_stage3;
    assign valid_out = valid_stage3;
    assign ready_out = ready_in & ~stall_stage3;
    
endmodule