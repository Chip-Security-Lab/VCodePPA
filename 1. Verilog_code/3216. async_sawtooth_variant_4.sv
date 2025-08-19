//SystemVerilog
module async_sawtooth(
    input clock,
    input arst,
    input [7:0] increment,
    output reg [9:0] sawtooth_out
);

    // 优化的pipeline registers
    reg [7:0] inc_pipe;
    reg [9:0] next_value;
    reg valid_pipe;
    
    // 移除不必要的wire声明，直接在always块中计算
    
    // 优化的单级流水线，平衡逻辑和时序
    always @(posedge clock or posedge arst) begin
        if (arst) begin
            inc_pipe <= 8'h00;
            valid_pipe <= 1'b0;
            next_value <= 10'h000;
            sawtooth_out <= 10'h000;
        end else begin
            // 捕获输入
            inc_pipe <= increment;
            valid_pipe <= 1'b1;
            
            // 预计算下一个值
            next_value <= sawtooth_out + {2'b00, inc_pipe};
            
            // 条件更新输出以减少切换活动
            if (valid_pipe) begin
                sawtooth_out <= next_value;
            end
        end
    end

endmodule