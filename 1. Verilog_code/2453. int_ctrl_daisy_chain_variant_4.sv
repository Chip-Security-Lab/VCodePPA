//SystemVerilog
//IEEE 1364-2005
module int_ctrl_daisy_chain #(parameter CHAIN=4)(
    input wire clk, 
    input wire ack_in,
    output wire ack_out,
    input wire [CHAIN-1:0] int_req,
    output reg [CHAIN-1:0] int_ack
);
    // 通过打断链路并将ack_chain的寄存器推至any_req判断之后，减少输入到第一级寄存器的延迟
    reg [CHAIN-2:0] ack_chain_delayed;
    reg ack_in_reg;
    reg any_req_reg;
    
    // 为高扇出信号添加缓冲寄存器
    reg ack_in_reg_buf1, ack_in_reg_buf2;
    reg any_req_reg_buf1, any_req_reg_buf2;
    reg [CHAIN-2:0] ack_chain_delayed_buf1, ack_chain_delayed_buf2;
    
    // 移动靠近输入的寄存器，将输入信号先打一拍，减少了输入端到寄存器的路径
    always @(posedge clk) begin
        ack_in_reg <= ack_in;
        any_req_reg <= |int_req;
    end
    
    // 为高扇出信号添加缓冲级
    always @(posedge clk) begin
        // 第一级缓冲
        ack_in_reg_buf1 <= ack_in_reg;
        ack_in_reg_buf2 <= ack_in_reg;
        
        any_req_reg_buf1 <= any_req_reg;
        any_req_reg_buf2 <= any_req_reg;
    end
    
    // 优化的ack_chain实现，将寄存器后移
    always @(posedge clk) begin
        if (CHAIN > 1) begin : shift_gen
            ack_chain_delayed[0] <= ack_in_reg;
            if (CHAIN > 2) begin
                ack_chain_delayed[CHAIN-2:1] <= ack_chain_delayed[CHAIN-3:0];
            end
        end
    end
    
    // 为ack_chain_delayed添加缓冲级
    always @(posedge clk) begin
        if (CHAIN > 1) begin
            ack_chain_delayed_buf1 <= ack_chain_delayed;
            ack_chain_delayed_buf2 <= ack_chain_delayed;
        end
    end
    
    // 优化int_ack的生成逻辑，使用缓冲寄存器来分散负载
    always @(posedge clk) begin
        // 分解为先寄存组合操作的结果，再生成输出
        if (CHAIN > 1) begin
            int_ack[0] <= ack_in_reg_buf1 & any_req_reg_buf1;
            
            // 使用缓冲寄存器来平衡各路径负载
            if (CHAIN <= 4) begin
                int_ack[CHAIN-1:1] <= ack_chain_delayed_buf1 & {(CHAIN-1){any_req_reg_buf1}};
            end else begin
                // 将负载分为两部分，分别使用不同的缓冲级
                int_ack[CHAIN/2:1] <= ack_chain_delayed_buf1[CHAIN/2-1:0] & {(CHAIN/2){any_req_reg_buf1}};
                int_ack[CHAIN-1:CHAIN/2+1] <= ack_chain_delayed_buf2[CHAIN-2:CHAIN/2] & {(CHAIN-1-CHAIN/2){any_req_reg_buf2}};
            end
        end else begin
            int_ack <= ack_in_reg_buf1 & any_req_reg_buf1;
        end
    end
    
    // ack_out信号直接从寄存的any_req输出，减少输出端延迟
    assign ack_out = any_req_reg;
    
    // 初始化块
    initial begin
        ack_chain_delayed = {(CHAIN-1){1'b0}};
        ack_in_reg = 1'b0;
        any_req_reg = 1'b0;
        int_ack = {CHAIN{1'b0}};
        
        // 初始化缓冲寄存器
        ack_in_reg_buf1 = 1'b0;
        ack_in_reg_buf2 = 1'b0;
        any_req_reg_buf1 = 1'b0;
        any_req_reg_buf2 = 1'b0;
        if (CHAIN > 1) begin
            ack_chain_delayed_buf1 = {(CHAIN-1){1'b0}};
            ack_chain_delayed_buf2 = {(CHAIN-1){1'b0}};
        end
    end
endmodule