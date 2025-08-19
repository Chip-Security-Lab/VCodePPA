//SystemVerilog
module shift_buffer #(
    parameter WIDTH = 8,
    parameter STAGES = 4
)(
    input wire clk,
    input wire rst_n,        // 添加复位信号
    input wire valid_in,     // 输入数据有效信号
    input wire ready_out,    // 下游模块准备接收数据
    output wire ready_in,    // 准备接收新数据信号
    input wire [WIDTH-1:0] data_in,
    output wire valid_out,   // 输出数据有效信号
    output wire [WIDTH-1:0] data_out
);
    // 流水线数据寄存器
    reg [WIDTH-1:0] shift_reg_stage [0:STAGES-1];
    
    // 流水线控制信号
    reg [STAGES-1:0] valid_stage;
    
    // 添加缓冲寄存器以减少高扇出
    reg [WIDTH-1:0] shift_reg_buf1 [0:STAGES/2-1];
    reg [WIDTH-1:0] shift_reg_buf2 [0:STAGES/2-1];
    reg [STAGES/2-1:0] valid_stage_buf1;
    reg [STAGES/2-1:0] valid_stage_buf2;
    
    // 迭代变量的缓冲
    reg [2:0] i_buf1, i_buf2;
    
    // 流水线控制逻辑
    assign ready_in = ready_out || !valid_stage[STAGES-1];
    assign valid_out = valid_stage[STAGES-1];
    assign data_out = shift_reg_stage[STAGES-1];
    
    integer i;
    
    // 为高扇出信号添加缓冲寄存器
    always @(posedge clk) begin
        if (!rst_n) begin
            i_buf1 <= 0;
            i_buf2 <= 0;
            // 清除缓冲寄存器
            for (i = 0; i < STAGES/2; i = i + 1) begin
                shift_reg_buf1[i] <= {WIDTH{1'b0}};
                shift_reg_buf2[i] <= {WIDTH{1'b0}};
                valid_stage_buf1[i] <= 1'b0;
                valid_stage_buf2[i] <= 1'b0;
            end
        end else begin
            // 更新缓冲寄存器
            i_buf1 <= (i < STAGES/2) ? i : 0;
            i_buf2 <= (i >= STAGES/2 && i < STAGES) ? i - STAGES/2 : 0;
            
            for (i = 0; i < STAGES/2; i = i + 1) begin
                shift_reg_buf1[i] <= shift_reg_stage[i];
                shift_reg_buf2[i] <= shift_reg_stage[i+STAGES/2];
                valid_stage_buf1[i] <= valid_stage[i];
                valid_stage_buf2[i] <= valid_stage[i+STAGES/2];
            end
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位所有流水线寄存器
            for (i = 0; i < STAGES; i = i + 1) begin
                shift_reg_stage[i] <= {WIDTH{1'b0}};
                valid_stage[i] <= 1'b0;
            end
        end else if (ready_in) begin
            // 移动数据到第一级
            shift_reg_stage[0] <= data_in;
            valid_stage[0] <= valid_in;
            
            // 移动数据通过流水线的前半部分 - 使用buf1缓冲
            for (i = 1; i < STAGES/2; i = i + 1) begin
                shift_reg_stage[i] <= shift_reg_buf1[i-1];
                valid_stage[i] <= valid_stage_buf1[i-1];
            end
            
            // 移动数据通过流水线的后半部分 - 使用buf2缓冲
            for (i = STAGES/2; i < STAGES; i = i + 1) begin
                shift_reg_stage[i] <= shift_reg_buf2[i-STAGES/2-1];
                valid_stage[i] <= valid_stage_buf2[i-STAGES/2-1];
            end
            
            // 特殊处理中间连接点
            shift_reg_stage[STAGES/2] <= shift_reg_buf1[STAGES/2-1];
            valid_stage[STAGES/2] <= valid_stage_buf1[STAGES/2-1];
        end
    end
endmodule