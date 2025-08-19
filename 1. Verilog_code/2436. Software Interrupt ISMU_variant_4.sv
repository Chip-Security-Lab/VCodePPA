//SystemVerilog
module sw_interrupt_ismu(
    input  wire        clock,
    input  wire        reset_n,
    input  wire [3:0]  hw_int,
    input  wire [3:0]  sw_int_set,
    input  wire [3:0]  sw_int_clr,
    input  wire        valid_in,
    output reg         valid_out,
    output reg  [3:0]  combined_int
);
    // 软件中断寄存器
    reg [3:0] sw_int_reg;
    
    // 数据流阶段信号定义
    // 输入阶段 - 寄存输入信号
    reg        valid_input_stage;
    reg [3:0]  hw_int_input_stage;
    reg [3:0]  sw_int_set_input_stage;
    reg [3:0]  sw_int_clr_input_stage;
    
    // 处理阶段 - 计算软件中断状态
    reg        valid_process_stage;
    reg [3:0]  hw_int_process_stage;
    reg [3:0]  sw_int_process_stage;
    
    // 组合阶段 - 准备输出最终中断状态
    wire [3:0] next_sw_int;
    
    // 软件中断计算逻辑
    // 优化后的组合逻辑，减少路径深度
    assign next_sw_int = (sw_int_reg | sw_int_set_input_stage) & ~sw_int_clr_input_stage;
    
    // 数据通路控制和流水线寄存器更新
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            // 异步复位所有流水线寄存器
            // 输入阶段复位
            valid_input_stage     <= 1'b0;
            hw_int_input_stage    <= 4'b0000;
            sw_int_set_input_stage <= 4'b0000;
            sw_int_clr_input_stage <= 4'b0000;
            
            // 处理阶段复位
            valid_process_stage   <= 1'b0;
            hw_int_process_stage  <= 4'b0000;
            sw_int_process_stage  <= 4'b0000;
            sw_int_reg            <= 4'b0000;
            
            // 输出阶段复位
            valid_out             <= 1'b0;
            combined_int          <= 4'b0000;
        end 
        else begin
            // 输入阶段 - 寄存输入信号
            valid_input_stage     <= valid_in;
            hw_int_input_stage    <= hw_int;
            sw_int_set_input_stage <= sw_int_set;
            sw_int_clr_input_stage <= sw_int_clr;
            
            // 处理阶段 - 更新软件中断状态和传递硬件中断
            valid_process_stage   <= valid_input_stage;
            hw_int_process_stage  <= hw_int_input_stage;
            sw_int_reg            <= next_sw_int;
            sw_int_process_stage  <= next_sw_int;
            
            // 输出阶段 - 计算最终组合中断
            valid_out             <= valid_process_stage;
            combined_int          <= hw_int_process_stage | sw_int_process_stage;
        end
    end
endmodule