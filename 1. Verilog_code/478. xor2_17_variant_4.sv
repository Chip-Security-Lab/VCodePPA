//SystemVerilog
module xor2_17 (
    input  wire        clk,        // 时钟信号
    input  wire        rst_n,      // 低电平有效复位信号
    input  wire        data_valid, // 输入数据有效信号
    input  wire        A, B, C, D, // 输入数据位
    output reg         Y_valid,    // 输出数据有效信号
    output reg         Y           // 输出结果
);
    // ===== 数据流水线寄存器定义 =====
    // 流水线阶段1: 初始计算阶段
    reg                 pipe1_valid;   // 第一级流水线有效信号
    reg                 pipe1_xor_ab;  // A⊕B结果
    reg                 pipe1_xor_cd;  // C⊕D结果
    
    // 流水线阶段2: 中间计算阶段 
    reg                 pipe2_valid;   // 第二级流水线有效信号
    reg                 pipe2_result;  // 最终异或结果
    
    // ===== 流水线阶段1: 初始计算 =====
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 异步复位所有阶段1寄存器
            pipe1_valid <= 1'b0;
            pipe1_xor_ab <= 1'b0;
            pipe1_xor_cd <= 1'b0;
        end 
        else begin
            // 传递有效信号
            pipe1_valid <= data_valid;
            
            // 当输入有效时执行计算
            if (data_valid) begin
                // 并行计算两路异或
                pipe1_xor_ab <= A ^ B;  // 第一对操作数异或
                pipe1_xor_cd <= C ^ D;  // 第二对操作数异或
            end
        end
    end
    
    // ===== 流水线阶段2: 中间计算 =====
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 异步复位所有阶段2寄存器
            pipe2_valid <= 1'b0;
            pipe2_result <= 1'b0;
        end 
        else begin
            // 传递有效信号
            pipe2_valid <= pipe1_valid;
            
            // 当前级数据有效时执行计算
            if (pipe1_valid) begin
                // 合并两路异或结果
                pipe2_result <= pipe1_xor_ab ^ pipe1_xor_cd;
            end
        end
    end
    
    // ===== 输出阶段: 最终结果输出 =====
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 异步复位输出寄存器
            Y_valid <= 1'b0;
            Y <= 1'b0;
        end 
        else begin
            // 传递有效信号至输出
            Y_valid <= pipe2_valid;
            
            // 当前级数据有效时更新输出
            if (pipe2_valid) begin
                Y <= pipe2_result;
            end
        end
    end
    
endmodule