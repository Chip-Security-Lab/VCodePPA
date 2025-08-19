//SystemVerilog
module int_ctrl_daisy_chain #(parameter CHAIN=4)(
    input clk, ack_in,
    output ack_out,
    input [CHAIN-1:0] int_req,
    output reg [CHAIN-1:0] int_ack
);
    reg [CHAIN-1:0] ack_chain;
    wire [CHAIN-1:0] next_ack_chain;
    wire [CHAIN-1:0] comp_result;
    
    // 二进制补码计算
    wire [CHAIN-1:0] complemented_value;
    wire [CHAIN-1:0] ones_complement;
    wire carry_out;
    
    // 初始化寄存器
    initial begin
        ack_chain = {CHAIN{1'b0}};
        int_ack = {CHAIN{1'b0}};
    end
    
    // 对0进行补码运算，生成基准值
    assign ones_complement = ~{CHAIN{1'b0}};
    assign {carry_out, complemented_value} = ones_complement + {{(CHAIN-1){1'b0}}, 1'b1};
    
    // 使用二进制补码减法算法实现ack_chain的更新
    assign next_ack_chain = ack_in ? 
                            {ack_chain[CHAIN-2:0], 1'b1} : 
                            (ack_chain - complemented_value);
    
    // 更新ack_chain和int_ack
    always @(posedge clk) begin
        ack_chain <= next_ack_chain;
        int_ack <= ack_chain & int_req;
    end
    
    // 中断输出信号生成
    assign ack_out = |int_req;
endmodule