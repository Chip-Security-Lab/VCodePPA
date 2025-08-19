//SystemVerilog
module basic_sync_timer #(parameter WIDTH = 32)(
    input wire clk, rst_n, enable,
    output reg [WIDTH-1:0] count,
    output reg timeout
);
    // 寄存输入信号以优化前端时序
    reg rst_n_reg, enable_reg;
    
    // 控制状态编码
    localparam RESET = 2'b01;
    localparam ENABLED = 2'b10;
    localparam IDLE = 2'b00;
    
    // 寄存输入信号
    always @(posedge clk) begin
        rst_n_reg <= rst_n;
        enable_reg <= enable;
    end
    
    // 主状态机 - 使用寄存后的输入信号
    always @(posedge clk) begin
        if (!rst_n_reg) begin
            // 复位逻辑
            count <= {WIDTH{1'b0}};
            timeout <= 1'b0;
        end else if (enable_reg) begin
            // 启用计数
            count <= count + 1'b1;
            timeout <= (count == {WIDTH{1'b1}});
        end
        // 在idle状态保持当前值
    end
endmodule