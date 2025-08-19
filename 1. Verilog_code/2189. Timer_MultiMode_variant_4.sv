//SystemVerilog
//IEEE 1364-2005 Verilog
module Timer_MultiMode #(parameter MODE=0) (
    input clk, rst_n,
    input [7:0] period,
    output reg out
);
    reg [7:0] cnt;
    reg period_is_zero;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 8'b0;
            out <= 1'b0;
            period_is_zero <= 1'b0;
        end else begin
            cnt <= cnt + 1'b1;
            period_is_zero <= (period == 8'b0);
            
            case(MODE)
                0: begin
                    // 使用范围检查优化比较逻辑
                    if (cnt == 8'hFF && period == 8'h0) 
                        out <= 1'b1;
                    else if (cnt == (period - 1'b1))
                        out <= 1'b1;
                    else
                        out <= 1'b0;
                end
                1: begin
                    // 合并条件判断，减少比较次数
                    if (cnt == period && !period_is_zero)
                        out <= 1'b1;
                    else if (cnt == 8'b0 && !period_is_zero)
                        out <= 1'b0;
                end
                2: begin
                    // 使用位掩码加速比较
                    out <= ((cnt & 4'hF) == {1'b0, period[2:0]}) ? 1'b1 : 1'b0;
                end
                default: out <= 1'b0;
            endcase
        end
    end
endmodule