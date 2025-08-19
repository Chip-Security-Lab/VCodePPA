//SystemVerilog
module switch_debouncer #(parameter DEBOUNCE_COUNT = 1000) (
    input  wire clk,
    input  wire reset,
    input  wire switch_in,
    output reg  clean_out
);
    localparam CNT_WIDTH = $clog2(DEBOUNCE_COUNT);
    
    // 将输入同步寄存器直接放在输入端
    wire switch_ff1;
    reg switch_ff2;
    
    // 输入寄存器前移
    (* keep = "true" *) reg switch_input_reg;
    
    // 缓冲reset信号到整个设计中
    wire reset_buf1;
    reg reset_buf2;
    
    // 计数器寄存器
    reg [CNT_WIDTH-1:0] counter;
    wire counter_reset;
    wire counter_increment;
    
    // 比较结果寄存器
    wire comp_result; 
    reg comp_result_buf;
    
    // 阈值检测寄存器
    wire counter_at_max;
    
    // 输入寄存器前移
    always @(posedge clk) begin
        switch_input_reg <= switch_in;
    end
    
    // 将第一级同步器移动到输入缓冲后
    assign switch_ff1 = switch_input_reg;
    
    // 第二级同步器
    always @(posedge clk) begin
        switch_ff2 <= switch_ff1;
    end
    
    // Reset缓冲 - 前移到输入端
    assign reset_buf1 = reset;
    
    // 第二级reset缓冲
    always @(posedge clk) begin
        reset_buf2 <= reset_buf1;
    end
    
    // 比较逻辑优化 - 使用组合逻辑而非寄存器
    assign comp_result = (switch_ff2 != clean_out);
    
    // 仅使用单级缓冲减少延迟
    always @(posedge clk) begin
        comp_result_buf <= comp_result;
    end
    
    // 阈值检测优化为组合逻辑
    assign counter_at_max = (counter == DEBOUNCE_COUNT-1);
    
    // 计数器控制逻辑优化
    assign counter_reset = reset_buf2 || !comp_result_buf || (counter_at_max && comp_result_buf);
    assign counter_increment = comp_result_buf && !counter_at_max;
    
    // 计数器操作
    always @(posedge clk) begin
        if (counter_reset) begin
            counter <= {CNT_WIDTH{1'b0}};
        end else if (counter_increment) begin
            counter <= counter + 1'b1;
        end
    end
    
    // 输出逻辑
    always @(posedge clk) begin
        if (reset_buf2) begin
            clean_out <= 1'b0;
        end else if (counter_at_max && comp_result_buf) begin
            clean_out <= switch_ff2;
        end
    end
endmodule