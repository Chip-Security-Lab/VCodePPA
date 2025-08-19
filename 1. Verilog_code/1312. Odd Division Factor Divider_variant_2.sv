//SystemVerilog
// 顶层模块
module odd_div #(parameter DIV = 3) (
    input  wire clk_i,
    input  wire reset_i,
    output wire clk_o
);
    // 模块内部信号
    localparam WIDTH = $clog2(DIV);
    
    wire [WIDTH-1:0] counter_value;
    wire count_max_flag;
    wire clk_toggle;
    
    // 计数器子模块
    counter_module #(
        .DIV(DIV),
        .WIDTH(WIDTH)
    ) counter_inst (
        .clk_i(clk_i),
        .reset_i(reset_i),
        .count_max_o(count_max_flag),
        .counter_value_o(counter_value)
    );
    
    // 时钟生成子模块
    clock_generator clock_gen_inst (
        .clk_i(clk_i),
        .reset_i(reset_i),
        .count_max_i(count_max_flag),
        .clk_o(clk_o)
    );
    
endmodule

// 计数器子模块
module counter_module #(
    parameter DIV = 3,
    parameter WIDTH = $clog2(DIV)
) (
    input  wire clk_i,
    input  wire reset_i,
    output wire count_max_o,
    output reg [WIDTH-1:0] counter_value_o
);
    // 计算最大计数值
    localparam [WIDTH-1:0] MAX_COUNT = DIV - 1;
    
    // 最大计数值检测
    assign count_max_o = (counter_value_o == MAX_COUNT);
    
    // 计数器逻辑
    always @(posedge clk_i) begin
        if (reset_i) begin
            counter_value_o <= {WIDTH{1'b0}};
        end else begin
            counter_value_o <= count_max_o ? {WIDTH{1'b0}} : counter_value_o + 1'b1;
        end
    end
endmodule

// 时钟生成器子模块
module clock_generator (
    input  wire clk_i,
    input  wire reset_i,
    input  wire count_max_i,
    output reg  clk_o
);
    // 时钟生成逻辑
    always @(posedge clk_i) begin
        if (reset_i) begin
            clk_o <= 1'b0;
        end else begin
            clk_o <= count_max_i ? ~clk_o : clk_o;
        end
    end
endmodule