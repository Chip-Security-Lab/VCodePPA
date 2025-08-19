//SystemVerilog
module error_detect_bridge #(parameter DWIDTH=32) (
    input clk, rst_n,
    input [DWIDTH-1:0] in_data,
    input in_valid,
    output reg in_ready,
    output reg [DWIDTH-1:0] out_data,
    output reg out_valid,
    output reg error,
    input out_ready
);
    // 内部信号声明
    wire calc_parity;
    reg next_out_valid;
    reg next_in_ready;
    reg next_error;
    reg [DWIDTH-1:0] next_out_data;
    
    // 组合逻辑部分：奇偶校验计算
    parity_calculator_optimized #(.WIDTH(DWIDTH)) parity_calc (
        .data(in_data),
        .parity(calc_parity)
    );
    
    // 组合逻辑部分：下一状态逻辑
    always @(*) begin
        // 默认保持当前状态
        next_out_valid = out_valid;
        next_in_ready = in_ready;
        next_error = error;
        next_out_data = out_data;
        
        if (in_valid && in_ready) begin
            next_out_data = in_data;
            next_out_valid = 1'b1;
            next_in_ready = 1'b0;
            next_error = calc_parity ? 1'b0 : 1'b1;  // 奇校验
        end else if (out_valid && out_ready) begin
            next_out_valid = 1'b0;
            next_in_ready = 1'b1;
            next_error = 1'b0;
        end
    end
    
    // 时序逻辑部分：寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid <= 1'b0;
            in_ready <= 1'b1;
            error <= 1'b0;
            out_data <= {DWIDTH{1'b0}};
        end else begin
            out_valid <= next_out_valid;
            in_ready <= next_in_ready;
            error <= next_error;
            out_data <= next_out_data;
        end
    end
endmodule

// 优化后的奇偶校验计算器，使用条件反相减法器算法实现
module parity_calculator_optimized #(parameter WIDTH=32) (
    input [WIDTH-1:0] data,
    output reg parity
);
    // 内部信号声明
    reg [7:0] byte_parity;
    wire [7:0] inverted_byte;
    wire [7:0] difference;
    wire borrow;
    
    // 使用8位条件反相减法器算法计算奇偶校验
    // 取数据的低8位用于示例
    assign inverted_byte = ~data[7:0];
    
    // 条件反相减法器实现
    // diff = a - b = a + ~b + 1 (反码加1)
    assign {borrow, difference} = 9'b100000000 + {1'b0, data[7:0]} + {1'b0, inverted_byte};
    
    // 根据减法结果计算奇偶校验
    always @(*) begin
        byte_parity = 0;
        for (int i = 0; i < 8; i = i + 1) begin
            byte_parity = byte_parity ^ difference[i];
        end
        
        // 计算整个数据的奇偶校验
        parity = byte_parity;
        for (int i = 8; i < WIDTH; i = i + 1) begin
            parity = parity ^ data[i];
        end
    end
endmodule