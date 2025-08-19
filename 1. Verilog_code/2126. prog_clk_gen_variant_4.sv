//SystemVerilog
module prog_clk_gen(
    input pclk,
    input presetn,
    input [7:0] div_ratio,
    output reg clk_out
);
    // 优化寄存器定义
    reg [7:0] div_ratio_reg;
    reg [7:0] counter;
    reg toggle_flag;
    
    // 预计算的标志位
    wire counter_reset;
    wire [7:0] half_div = {1'b0, div_ratio_reg[7:1]}; // 除以2计算
    
    // 路径平衡：将比较逻辑提前到组合逻辑中
    assign counter_reset = (counter >= (half_div - 8'd1));
    
    // 输入寄存
    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            div_ratio_reg <= 8'd0;
        end else begin
            div_ratio_reg <= div_ratio;
        end
    end
    
    // 计数器逻辑 - 优化关键路径
    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            counter <= 8'd0;
            toggle_flag <= 1'b0;
            clk_out <= 1'b0;
        end else begin
            if (counter_reset) begin
                counter <= 8'd0;
                toggle_flag <= ~toggle_flag;
                clk_out <= toggle_flag;
            end else begin
                counter <= counter + 8'd1;
            end
        end
    end
endmodule