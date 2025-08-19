//SystemVerilog
module dram_ctrl_temp_comp #(
    parameter BASE_REFRESH = 7800
)(
    input clk,
    input [7:0] temperature,
    output reg refresh_req
);

    // 内部信号定义
    reg [15:0] refresh_counter;
    reg [15:0] refresh_interval_reg;
    reg [15:0] temp_mult_reg;
    wire [15:0] refresh_interval;
    
    // 温度乘法计算流水线寄存器
    always @(posedge clk) begin
        temp_mult_reg <= temperature * 10;
    end
    
    // 计算刷新间隔
    assign refresh_interval = BASE_REFRESH + temp_mult_reg;
    
    // 刷新间隔寄存器
    always @(posedge clk) begin
        refresh_interval_reg <= refresh_interval;
    end
    
    // 刷新计数器逻辑
    always @(posedge clk) begin
        if(refresh_counter >= refresh_interval_reg) begin
            refresh_counter <= 0;
        end else begin
            refresh_counter <= refresh_counter + 1;
        end
    end
    
    // 刷新请求生成逻辑
    always @(posedge clk) begin
        refresh_req <= (refresh_counter >= refresh_interval_reg);
    end

endmodule