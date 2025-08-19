module ChainVotingRecovery #(parameter WIDTH=4, STAGES=5) (
    input clk,
    input [WIDTH-1:0] noisy_input,
    output reg [WIDTH-1:0] voted_output
);
    reg [WIDTH-1:0] delay_chain [0:STAGES-1];
    wire [WIDTH+2:0] sum_bits;  // 更宽以容纳和
    integer i;

    always @(posedge clk) begin
        // 修复错误的数组赋值
        for (i = STAGES-1; i > 0; i = i - 1) begin
            delay_chain[i] <= delay_chain[i-1];
        end
        delay_chain[0] <= noisy_input;
    end
    
    // 计算位总和
    assign sum_bits = delay_chain[0] + delay_chain[1] + delay_chain[2] + 
                     delay_chain[3] + delay_chain[4];
    
    // 决定多数投票
    always @(posedge clk) begin
        voted_output <= (sum_bits > (STAGES/2)) ? {WIDTH{1'b1}} : {WIDTH{1'b0}};
    end
endmodule