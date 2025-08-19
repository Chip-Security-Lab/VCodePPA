//SystemVerilog (IEEE 1364-2005)
module pl_reg_divider #(parameter W=4, DIV=4) (
    input wire clk, rst,
    input wire [W-1:0] data_in,
    output wire [W-1:0] data_out
);
    // 内部连线
    wire counter_max;
    wire [DIV-1:0] counter_value;
    
    // 实例化子模块
    counter_module #(
        .DIV(DIV)
    ) counter_inst (
        .clk(clk),
        .rst(rst),
        .counter_max(counter_max),
        .counter_value(counter_value)
    );
    
    data_register #(
        .W(W)
    ) data_reg_inst (
        .clk(clk),
        .rst(rst),
        .counter_max(counter_max),
        .data_in(data_in),
        .data_out(data_out)
    );
endmodule

// 计数器子模块
module counter_module #(parameter DIV=4) (
    input wire clk, rst,
    output wire counter_max,
    output reg [DIV-1:0] counter_value
);
    // 达到最大计数值的标志
    assign counter_max = &counter_value;
    
    // 计数器逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter_value <= {DIV{1'b0}};
        end else begin
            counter_value <= counter_value + 1'b1;
        end
    end
endmodule

// 数据寄存器子模块
module data_register #(parameter W=4) (
    input wire clk, rst,
    input wire counter_max,
    input wire [W-1:0] data_in,
    output reg [W-1:0] data_out
);
    // 数据输出寄存器逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_out <= {W{1'b0}};
        end else if (counter_max) begin
            data_out <= data_in;
        end
    end
endmodule