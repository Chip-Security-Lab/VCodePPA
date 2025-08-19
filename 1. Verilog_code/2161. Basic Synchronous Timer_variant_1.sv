//SystemVerilog
module basic_sync_timer #(parameter WIDTH = 32)(
    input wire clk, rst_n, enable,
    output reg [WIDTH-1:0] count,
    output reg timeout
);
    // 注册输入信号以减少输入到第一级寄存器的延迟
    reg enable_r;
    
    // 预计算下一个计数值和超时状态
    wire [WIDTH-1:0] next_count;
    wire next_timeout;
    
    // 在寄存器后进行计算，减少关键路径
    assign next_count = count + {{(WIDTH-1){1'b0}}, enable_r};
    assign next_timeout = &count & enable_r;
    
    // 对输入信号进行寄存
    always @(posedge clk) begin
        if (!rst_n) begin
            enable_r <= 1'b0;
        end else begin
            enable_r <= enable;
        end
    end
    
    // 主状态更新逻辑
    always @(posedge clk) begin
        if (!rst_n) begin
            count <= {WIDTH{1'b0}};
            timeout <= 1'b0;
        end else begin
            count <= next_count;
            timeout <= next_timeout;
        end
    end
endmodule