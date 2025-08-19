//SystemVerilog
module int_ctrl_delay #(
    parameter DLY = 4  // 默认延迟级数
)(
    input  wire clk,
    input  wire int_in,
    output wire int_out
);

    // 增加流水线深度，将每个延迟单元拆分为更细粒度的阶段
    reg [DLY-1:0] delay_chain_stage1;
    reg [DLY-1:0] delay_chain_stage2;
    
    // 借位减法器实现延迟逻辑（使用位串行借位运算代替简单的寄存器传递）
    wire [DLY:0] borrow; // 借位信号
    
    assign borrow[0] = 1'b0; // 初始借位为0
    
    always @(posedge clk) begin
        // 第一级延迟链
        for(integer i = 0; i < DLY; i = i + 1) begin
            if(i == 0)
                delay_chain_stage1[i] <= int_in ^ 1'b1 ^ borrow[i];
            else
                delay_chain_stage1[i] <= delay_chain_stage1[i-1] ^ 1'b1 ^ borrow[i];
        end
        
        // 第二级延迟链
        delay_chain_stage2 <= delay_chain_stage1;
    end
    
    // 计算每一位的借位
    genvar j;
    generate
        for(j = 0; j < DLY; j = j + 1) begin : gen_borrow
            assign borrow[j+1] = (j == 0) ? 
                               (~int_in & 1'b1) | (1'b1 & borrow[j]) : 
                               (~delay_chain_stage1[j-1] & 1'b1) | (1'b1 & borrow[j]);
        end
    endgenerate
    
    // 输出最终延迟后的信号
    assign int_out = delay_chain_stage2[DLY-1];

endmodule