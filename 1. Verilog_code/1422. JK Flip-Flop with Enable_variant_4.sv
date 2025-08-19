//SystemVerilog
module jk_ff_enable (
    input wire clock_in,
    input wire enable_sig,
    input wire j_input,
    input wire k_input,
    output reg q_output
);
    // 使用组合逻辑提取共同条件变量
    wire [1:0] jk_pair;
    assign jk_pair = {j_input, k_input};
    
    always @(posedge clock_in) begin
        if (enable_sig) begin
            case (jk_pair)
                2'b00: q_output <= q_output;    // 保持现有状态
                2'b01: q_output <= 1'b0;        // 复位
                2'b10: q_output <= 1'b1;        // 置位
                2'b11: q_output <= ~q_output;   // 翻转
            endcase
        end
    end
endmodule