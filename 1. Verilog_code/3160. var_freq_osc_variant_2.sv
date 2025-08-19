//SystemVerilog
module var_freq_osc(
    input main_clk,
    input rst_n,
    input [7:0] freq_sel,
    output reg out_clk
);
    // 计数器和最大计数值
    reg [15:0] counter;
    wire [15:0] max_count;
    
    // 计算最大计数值
    assign max_count = {8'h00, ~freq_sel} + 16'd1;
    
    // 计数器控制块
    always @(posedge main_clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 16'd0;
        end else if (counter >= max_count - 1) begin
            counter <= 16'd0;
        end else begin
            counter <= counter + 1'b1;
        end
    end
    
    // 时钟输出控制块
    always @(posedge main_clk or negedge rst_n) begin
        if (!rst_n) begin
            out_clk <= 1'b0;
        end else if (counter >= max_count - 1) begin
            out_clk <= ~out_clk;
        end
    end
endmodule