//SystemVerilog
module shift_add_multiplier #(
    parameter WIDTH = 8
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output reg [2*WIDTH-1:0] product
);

    reg [2*WIDTH-1:0] acc;
    reg [WIDTH-1:0] multiplier;
    reg [$clog2(WIDTH)-1:0] count;
    wire count_done;
    
    // 计算完成标志
    assign count_done = (count == WIDTH);
    
    // 复位和初始化逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc <= 0;
            multiplier <= b;
            count <= 0;
            product <= 0;
        end
    end
    
    // 累加器更新逻辑
    always @(posedge clk) begin
        if (rst_n && !count_done && multiplier[0]) begin
            acc <= acc + (a << count);
        end
    end
    
    // 乘数移位和计数更新逻辑
    always @(posedge clk) begin
        if (rst_n && !count_done) begin
            multiplier <= multiplier >> 1;
            count <= count + 1;
        end
    end
    
    // 结果输出和重置逻辑
    always @(posedge clk) begin
        if (rst_n && count_done) begin
            product <= acc;
            acc <= 0;
            multiplier <= b;
            count <= 0;
        end
    end

endmodule