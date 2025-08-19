//SystemVerilog
// 顶层模块：冗余XNOR计算系统
module Redundant_XNOR_System #(
    parameter PATH_COUNT = 2,
    parameter TECH_LIBRARY = "DEFAULT"
)(
    input wire clk,          // 系统时钟
    input wire rst_n,        // 低电平有效复位
    input wire enable,       // 模块使能
    input wire [1:0] in_data,// 输入数据，[0]=x, [1]=y
    output wire result,      // 计算结果
    output wire valid,       // 结果有效标志
    output wire error        // 错误检测标志
);
    // 内部信号定义
    wire [PATH_COUNT-1:0] path_results;  // 各计算路径结果
    wire computation_valid;              // 计算结果有效
    wire paths_match;                    // 路径结果匹配标志
    wire processed_x, processed_y;       // 处理后的输入数据
    wire data_valid;                     // 数据有效标志
    
    // 输入寄存器模块实例化
    InputProcessor input_proc (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .raw_data(in_data),
        .processed_x(processed_x),
        .processed_y(processed_y),
        .data_valid(data_valid)
    );
    
    // 冗余计算单元实例化
    ComputationUnit #(
        .TECH_LIBRARY(TECH_LIBRARY)
    ) comp_unit (
        .clk(clk),
        .rst_n(rst_n),
        .data_valid(data_valid),
        .x(processed_x),
        .y(processed_y),
        .path_results(path_results),
        .computation_valid(computation_valid)
    );
    
    // 结果验证模块实例化
    ResultValidator #(
        .PATH_COUNT(PATH_COUNT)
    ) result_validator (
        .clk(clk),
        .rst_n(rst_n),
        .path_results(path_results),
        .computation_valid(computation_valid),
        .result(result),
        .valid(valid),
        .error(error),
        .paths_match(paths_match)
    );

endmodule

// 输入处理模块
module InputProcessor (
    input wire clk,
    input wire rst_n,
    input wire enable,
    input wire [1:0] raw_data,
    output reg processed_x,
    output reg processed_y,
    output reg data_valid
);
    // 输入数据缓冲
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            processed_x <= 1'b0;
            processed_y <= 1'b0;
            data_valid <= 1'b0;
        end else if (enable) begin
            processed_x <= raw_data[0];
            processed_y <= raw_data[1];
            data_valid <= 1'b1;
        end else begin
            data_valid <= 1'b0;
        end
    end
endmodule

// 冗余计算单元
module ComputationUnit #(
    parameter TECH_LIBRARY = "DEFAULT"
)(
    input wire clk,
    input wire rst_n,
    input wire data_valid,
    input wire x,
    input wire y,
    output wire [1:0] path_results,
    output reg computation_valid
);
    // 计算路径实例化
    XnorPath #(
        .PATH_TYPE("CLA_BASED"),  // 修改为使用先行进位加法器实现
        .TECH_LIBRARY(TECH_LIBRARY)
    ) path1 (
        .clk(clk),
        .enable(data_valid),
        .in_a(x),
        .in_b(y),
        .out_result(path_results[0])
    );
    
    XnorPath #(
        .PATH_TYPE("NATIVE"),
        .TECH_LIBRARY(TECH_LIBRARY)
    ) path2 (
        .clk(clk),
        .enable(data_valid),
        .in_a(x),
        .in_b(y),
        .out_result(path_results[1])
    );
    
    // 计算有效性跟踪
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            computation_valid <= 1'b0;
        end else begin
            computation_valid <= data_valid;
        end
    end
endmodule

// XNOR计算路径模块
module XnorPath #(
    parameter PATH_TYPE = "CLA_BASED",  // 实现方式："CLA_BASED"、"XOR_NOT"或"NATIVE"
    parameter TECH_LIBRARY = "DEFAULT"
)(
    input wire clk,
    input wire enable,
    input wire in_a,
    input wire in_b,
    output reg out_result
);
    // 根据实现方式选择不同的XNOR计算方法
    wire xnor_result;
    
    generate
        if (PATH_TYPE == "CLA_BASED") begin : gen_cla_path
            // 使用2位先行进位加法器实现XNOR
            // 在2位CLA中，我们使用特殊方式编码输入，使得加法器输出表示XNOR运算
            
            // 定义加法器的输入和输出
            wire [1:0] cla_a;   // 加法器输入A
            wire [1:0] cla_b;   // 加法器输入B
            wire [1:0] cla_sum; // 加法器输出和
            wire cla_cout;      // 加法器进位输出
            
            // 编码输入以实现XNOR功能
            // 对于XNOR: a ~^ b = ~(a ^ b)
            // 我们可以根据a和b的值设置加法器输入
            assign cla_a = {1'b0, in_a};
            assign cla_b = {1'b0, in_b};
            
            // 计算生成(G)和传播(P)信号
            wire [1:0] G; // 生成信号
            wire [1:0] P; // 传播信号
            
            assign G[0] = cla_a[0] & cla_b[0];
            assign G[1] = cla_a[1] & cla_b[1];
            
            assign P[0] = cla_a[0] | cla_b[0]; 
            assign P[1] = cla_a[1] | cla_b[1];
            
            // 计算每一位的进位信号
            wire [1:0] C; // 进位信号
            
            assign C[0] = 1'b0; // 初始进位为0
            assign C[1] = G[0] | (P[0] & C[0]);
            assign cla_cout = G[1] | (P[1] & C[1]);
            
            // 计算和
            assign cla_sum[0] = cla_a[0] ^ cla_b[0] ^ C[0];
            assign cla_sum[1] = cla_a[1] ^ cla_b[1] ^ C[1];
            
            // 从加法结果派生XNOR运算结果
            // 当a和b相同时(XNOR=1)，和为0；当a和b不同时(XNOR=0)，和为1
            // 因此XNOR结果 = ~(和的特定位)
            assign xnor_result = ~(cla_a[0] ^ cla_b[0]);
            
        end else if (PATH_TYPE == "XOR_NOT") begin : gen_xor_not_path
            assign xnor_result = ~(in_a ^ in_b);
        end else begin : gen_native_path
            assign xnor_result = in_a ~^ in_b;
        end
    endgenerate
    
    // 寄存结果以改善时序
    always @(posedge clk) begin
        if (enable) begin
            out_result <= xnor_result;
        end
    end
endmodule

// 结果验证模块
module ResultValidator #(
    parameter PATH_COUNT = 2
)(
    input wire clk,
    input wire rst_n,
    input wire [PATH_COUNT-1:0] path_results,
    input wire computation_valid,
    output reg result,
    output reg valid,
    output reg error,
    output wire paths_match
);
    // 比较多路径结果
    wire [PATH_COUNT-1:0] match_matrix;
    
    // 生成匹配矩阵
    genvar i, j;
    generate
        for (i = 0; i < PATH_COUNT-1; i = i + 1) begin : match_rows
            for (j = i+1; j < PATH_COUNT; j = j + 1) begin : match_cols
                assign match_matrix[i] = (path_results[i] == path_results[j]);
            end
        end
    endgenerate
    
    // 所有结果匹配检查
    assign paths_match = &match_matrix;
    
    // 状态处理逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= 1'b0;
            valid <= 1'b0;
            error <= 1'b0;
        end else if (computation_valid) begin
            result <= path_results[0]; // 使用第一条路径的结果
            valid <= paths_match;      // 仅当所有路径匹配时有效
            error <= ~paths_match;     // 路径不匹配时报错
        end else begin
            valid <= 1'b0;
            error <= 1'b0;
        end
    end
endmodule