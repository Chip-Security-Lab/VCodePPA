//SystemVerilog
module xor_function(
    input wire clk,     // 时钟信号
    input wire rst_n,   // 复位信号
    input wire a_in,    // 输入信号a
    input wire b_in,    // 输入信号b
    output wire y_out   // 输出信号
);
    // 内部信号
    wire a_stage1, b_stage1;
    wire xor_result;
    
    // 第一级流水线 - 输入寄存
    pipeline_register #(
        .WIDTH(2)
    ) input_stage (
        .clk(clk),
        .rst_n(rst_n),
        .data_in({a_in, b_in}),
        .data_out({a_stage1, b_stage1})
    );
    
    // 第二级流水线 - XOR运算
    pipeline_stage #(
        .WIDTH(1),
        .OPERATION("XOR")
    ) compute_stage (
        .clk(clk),
        .rst_n(rst_n),
        .a_in(a_stage1),
        .b_in(b_stage1),
        .result_out(xor_result)
    );
    
    // 第三级流水线 - 输出寄存
    pipeline_register #(
        .WIDTH(1)
    ) output_stage (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(xor_result),
        .data_out(y_out)
    );
    
endmodule

// 通用流水线寄存器模块
module pipeline_register #(
    parameter WIDTH = 1
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out
);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= {WIDTH{1'b0}};
        end
        else begin
            data_out <= data_in;
        end
    end
    
endmodule

// 通用逻辑操作流水线级
module pipeline_stage #(
    parameter WIDTH = 1,
    parameter OPERATION = "XOR"  // 可以扩展支持其他逻辑操作
)(
    input wire clk,
    input wire rst_n,
    input wire a_in,
    input wire b_in,
    output reg result_out
);
    
    reg result_comb;
    
    // 组合逻辑部分 - 可根据OPERATION参数扩展
    always @(*) begin
        case (OPERATION)
            "XOR": result_comb = a_in ^ b_in;
            "AND": result_comb = a_in & b_in;
            "OR":  result_comb = a_in | b_in;
            default: result_comb = a_in ^ b_in; // 默认为XOR
        endcase
    end
    
    // 时序逻辑部分
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_out <= 1'b0;
        end
        else begin
            result_out <= result_comb;
        end
    end
    
endmodule