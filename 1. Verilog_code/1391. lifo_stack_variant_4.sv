//SystemVerilog
module lifo_stack #(parameter DW=8, DEPTH=8) (
    input clk, rst_n,
    input push, pop,
    input [DW-1:0] din,
    output [DW-1:0] dout,
    output full, empty,
    // 新增流水线控制信号
    output reg ready_out,
    output reg valid_out
);
    // 内存存储
    reg [DW-1:0] mem [0:DEPTH-1];
    
    // 流水线阶段寄存器
    reg [2:0] ptr_stage1, ptr_stage2;
    reg [DW-1:0] din_stage1;
    reg push_stage1, pop_stage1;
    reg valid_stage1, valid_stage2;
    
    // 流水线控制信号
    wire execute_stage1 = (push_stage1 && !full_stage1) || (pop_stage1 && !empty_stage1);
    wire full_stage1 = (ptr_stage1 == DEPTH);
    wire empty_stage1 = (ptr_stage1 == 0);
    
    // 输出状态
    reg [DW-1:0] dout_reg;
    reg full_reg, empty_reg;
    
    // 第一级流水线: 命令接收和寄存
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            push_stage1 <= 0;
            pop_stage1 <= 0;
            din_stage1 <= 0;
            valid_stage1 <= 0;
            ptr_stage1 <= 0;
        end
        else begin
            push_stage1 <= push;
            pop_stage1 <= pop;
            din_stage1 <= din;
            valid_stage1 <= push || pop;
            
            // 指针逻辑移到第二阶段，这里只保留当前值
            if(valid_stage2 && push_stage1 && !pop_stage1 && !full_stage1) begin
                ptr_stage1 <= ptr_stage2 + 1;
            end
            else if(valid_stage2 && !push_stage1 && pop_stage1 && !empty_stage1) begin
                ptr_stage1 <= ptr_stage2 - 1;
            end
            else if(valid_stage2) begin
                ptr_stage1 <= ptr_stage2;
            end
        end
    end
    
    // 第二级流水线: 执行存储器操作
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            ptr_stage2 <= 0;
            valid_stage2 <= 0;
            dout_reg <= 0;
            valid_out <= 0;
            ready_out <= 1;
        end
        else begin
            valid_stage2 <= valid_stage1;
            ptr_stage2 <= ptr_stage1;
            
            // 执行存储器操作
            if(valid_stage1) begin
                if(push_stage1 && !pop_stage1 && !full_stage1) begin
                    mem[ptr_stage1] <= din_stage1;
                    dout_reg <= din_stage1;  // 预取输出
                end
                else if(!push_stage1 && pop_stage1 && !empty_stage1) begin
                    dout_reg <= mem[ptr_stage1-1];
                end
                else begin
                    dout_reg <= (empty_stage1) ? 0 : mem[ptr_stage1-1];
                end
                
                // 设置输出有效信号
                valid_out <= 1;
            end
            else begin
                valid_out <= 0;
            end
            
            // 计算并寄存状态
            full_reg <= (ptr_stage1 == DEPTH);
            empty_reg <= (ptr_stage1 == 0);
            
            // 设置就绪信号
            ready_out <= 1; // 始终可以接收新命令
        end
    end
    
    // 输出信号连接
    assign dout = dout_reg;
    assign full = full_reg;
    assign empty = empty_reg;
    
endmodule