//SystemVerilog
module int_ctrl_daisy_chain #(parameter CHAIN=4)(
    input clk, ack_in,
    output ack_out,
    input [CHAIN-1:0] int_req,
    output [CHAIN-1:0] int_ack
);
    // 内部信号声明
    reg [CHAIN-1:0] ack_chain_reg;
    reg [CHAIN-1:0] int_ack_reg;
    wire [CHAIN-1:0] next_ack_chain;
    wire [CHAIN-1:0] next_int_ack;
    
    // 高扇出信号的缓冲寄存器
    reg [CHAIN-1:0] next_ack_chain_buf1;
    reg [CHAIN-1:0] next_ack_chain_buf2;
    
    // 组合逻辑部分
    // 计算下一个周期的ack_chain值
    assign next_ack_chain = {ack_chain_reg[CHAIN-2:0], ack_in};
    
    // 计算下一个周期的int_ack值 - 使用缓冲寄存器降低扇出
    assign next_int_ack = next_ack_chain_buf2 & int_req;
    
    // 输出中断请求的OR结果
    assign ack_out = |int_req;
    
    // 连接输出
    assign int_ack = int_ack_reg;
    
    // 时序逻辑部分
    always @(posedge clk) begin
        // 更新主寄存器
        ack_chain_reg <= next_ack_chain;
        int_ack_reg <= next_int_ack;
        
        // 更新缓冲寄存器 - 多级缓冲减少高扇出延迟
        next_ack_chain_buf1 <= next_ack_chain;
        next_ack_chain_buf2 <= next_ack_chain_buf1;
    end
    
    // 初始化块
    initial begin
        ack_chain_reg = {CHAIN{1'b0}};
        int_ack_reg = {CHAIN{1'b0}};
        next_ack_chain_buf1 = {CHAIN{1'b0}};
        next_ack_chain_buf2 = {CHAIN{1'b0}};
    end
endmodule