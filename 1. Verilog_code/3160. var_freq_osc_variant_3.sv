//SystemVerilog
module var_freq_osc(
    input main_clk,
    input rst_n,
    input [7:0] freq_sel,
    output reg out_clk
);
    reg [15:0] counter;
    reg [15:0] target;
    
    // 预计算目标值以减少关键路径延迟
    always @(posedge main_clk or negedge rst_n) begin
        if (!rst_n)
            target <= 16'd1;
        else
            target <= {8'h00, ~freq_sel} + 16'd1;
    end
    
    // 使用提前比较减少时序路径
    always @(posedge main_clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 16'd0;
            out_clk <= 1'b0;
        end else if (counter == target - 1'b1) begin
            counter <= 16'd0;
            out_clk <= ~out_clk;
        end else
            counter <= counter + 1'b1;
    end
endmodule