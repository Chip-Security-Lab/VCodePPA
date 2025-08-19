//SystemVerilog
module Parity_XNOR_Valid_Ready (
    input  wire        clk,           // 时钟
    input  wire        rst_n,         // 复位信号，低电平有效
    
    // 输入接口 (Valid-Ready)
    input  wire [7:0]  data_in,       // 输入数据
    input  wire        valid_in,      // 输入数据有效
    output wire        ready_out,     // 准备接收数据
    input  wire        last_in,       // 帧结束标志
    
    // 输出接口 (Valid-Ready)
    output wire        data_out,      // 输出校验位
    output wire        valid_out,     // 输出数据有效
    input  wire        ready_in,      // 下游准备接收数据
    output wire        last_out       // 帧结束标志
);

    // 内部信号和寄存器
    reg  processing;
    reg  output_valid;
    reg  output_last;
    reg  parity_reg;
    
    // 提前计算奇偶校验，避免组合逻辑延迟影响性能
    wire [3:0] partial_xor;
    wire [1:0] intermediate_xor;
    wire parity_result;
    
    // 计算奇偶校验 - 使用平衡树结构提高性能
    assign partial_xor[0] = data_in[0] ^ data_in[1];
    assign partial_xor[1] = data_in[2] ^ data_in[3];
    assign partial_xor[2] = data_in[4] ^ data_in[5];
    assign partial_xor[3] = data_in[6] ^ data_in[7];
    
    assign intermediate_xor[0] = partial_xor[0] ^ partial_xor[1];
    assign intermediate_xor[1] = partial_xor[2] ^ partial_xor[3];
    
    assign parity_result = ~(intermediate_xor[0] ^ intermediate_xor[1]);
    
    // 改进的握手逻辑
    assign ready_out = !processing || (ready_in && output_valid);
    
    // 输出端口连接
    assign data_out  = parity_reg;    // 注册输出以优化时序
    assign valid_out = output_valid;
    assign last_out  = output_last;
    
    // 数据处理和控制逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            processing   <= 1'b0;
            output_valid <= 1'b0;
            output_last  <= 1'b0;
            parity_reg   <= 1'b0;
        end else begin
            // 输入握手成功，处理新数据
            if (valid_in && ready_out) begin
                processing   <= 1'b1;
                parity_reg   <= parity_result;
                output_valid <= 1'b1;
                output_last  <= last_in;
            end 
            // 输出握手成功，完成当前处理
            else if (valid_out && ready_in) begin
                processing   <= 1'b0;
                output_valid <= 1'b0;
                output_last  <= 1'b0;
            end
        end
    end
    
endmodule