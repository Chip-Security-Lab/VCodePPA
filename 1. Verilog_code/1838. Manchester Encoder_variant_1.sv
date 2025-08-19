//SystemVerilog
module manchester_encoder (
    input  wire clk,
    input  wire rst_n,
    input  wire data_in,
    input  wire polarity,   // 0=rising=1, 1=falling=0
    output reg  manchester_out
);
    reg clk_div2;
    reg data_in_reg;
    reg polarity_reg;
    
    // 优化的时钟分频器，使用toggleFF设计模式
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            clk_div2 <= 1'b0;
        else
            clk_div2 <= ~clk_div2;
    end
    
    // 输入信号寄存器
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_reg <= 1'b0;
            polarity_reg <= 1'b0;
        end
        else begin
            data_in_reg <= data_in;
            polarity_reg <= polarity;
        end
    end
    
    // 优化的曼彻斯特逻辑计算和输出寄存器
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            manchester_out <= 1'b0;
        else 
            manchester_out <= (data_in_reg ^ clk_div2) ^ polarity_reg;
    end
endmodule