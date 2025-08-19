//SystemVerilog
module test_mode_xnor (
    input  wire clk,          // 添加时钟信号用于流水线
    input  wire rst_n,        // 添加复位信号
    input  wire test_mode,
    input  wire a,
    input  wire b,
    output wire y
);
    // 数据流阶段1: 输入寄存
    reg a_reg, b_reg, test_mode_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 1'b0;
            b_reg <= 1'b0;
            test_mode_reg <= 1'b0;
        end else begin
            a_reg <= a;
            b_reg <= b;
            test_mode_reg <= test_mode;
        end
    end
    
    // 数据流阶段2: XNOR计算
    wire xnor_result;
    reg  xnor_result_reg;
    
    logic_xnor_calculator xnor_calc (
        .in_a(a_reg),
        .in_b(b_reg),
        .result(xnor_result)
    );
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xnor_result_reg <= 1'b0;
        end else begin
            xnor_result_reg <= xnor_result;
        end
    end
    
    // 数据流阶段3: 输出选择
    wire final_output;
    reg  y_reg;
    
    output_selector out_sel (
        .test_mode_en(test_mode_reg),
        .xnor_value(xnor_result_reg),
        .final_output(final_output)
    );
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y_reg <= 1'b0;
        end else begin
            y_reg <= final_output;
        end
    end
    
    // 输出赋值
    assign y = y_reg;
    
endmodule

module logic_xnor_calculator (
    input  wire in_a,
    input  wire in_b,
    output wire result
);
    // 优化XNOR逻辑实现，拆分为多个简单逻辑运算，减少逻辑深度
    wire xor_result;
    
    // 先计算XOR结果
    assign xor_result = in_a ^ in_b;
    
    // 再求反得到XNOR结果
    assign result = ~xor_result;
endmodule

module output_selector (
    input  wire test_mode_en,
    input  wire xnor_value,
    output wire final_output
);
    // 使用三目运算进行输出选择，简化数据通路
    assign final_output = test_mode_en ? xnor_value : 1'b0;
endmodule