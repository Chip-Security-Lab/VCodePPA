//SystemVerilog
module counter_preload #(parameter WIDTH=4) (
    input clk, load, en,
    input [WIDTH-1:0] data,
    output reg [WIDTH-1:0] cnt
);
    // 注册输入信号
    reg load_reg, en_reg;
    reg [WIDTH-1:0] data_reg;
    reg [1:0] ctrl_reg;
    
    // 在时钟上升沿注册输入信号
    always @(posedge clk) begin
        load_reg <= load;
        en_reg <= en;
        data_reg <= data;
        ctrl_reg <= {load, en};
    end
    
    // 使用注册后的信号进行计数器逻辑
    always @(posedge clk) begin
        case(ctrl_reg)
            2'b10, 2'b11: cnt <= data_reg;    // load=1, 无论en为何值都加载数据
            2'b01:        cnt <= cnt + 1;     // load=0, en=1, 计数器加1
            2'b00:        cnt <= cnt;         // load=0, en=0, 保持不变
        endcase
    end
endmodule