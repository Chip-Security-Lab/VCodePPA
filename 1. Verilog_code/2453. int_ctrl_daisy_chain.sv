module int_ctrl_daisy_chain #(parameter CHAIN=4)(
    input clk, ack_in,
    output ack_out,
    input [CHAIN-1:0] int_req,
    output reg [CHAIN-1:0] int_ack
);
    reg [CHAIN-1:0] ack_chain;
    
    always @(posedge clk) begin
        ack_chain <= {ack_chain[CHAIN-2:0], ack_in};
        int_ack <= ack_chain & int_req;
    end
    
    // 修正输出赋值，使用连续赋值
    assign ack_out = |int_req;
    
    // 添加初始化逻辑
    initial begin
        ack_chain = {CHAIN{1'b0}};
        int_ack = {CHAIN{1'b0}};
    end
endmodule