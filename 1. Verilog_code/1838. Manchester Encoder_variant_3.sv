//SystemVerilog
module manchester_encoder (
    input  wire clk,
    input  wire rst_n,
    input  wire data_in,
    input  wire polarity,   // 0=rising=1, 1=falling=0
    output reg  manchester_out
);
    // 寄存器声明
    reg clk_div2;
    reg data_in_reg;
    reg polarity_reg;
    
    // 对输入信号进行寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_reg <= 1'b0;
            polarity_reg <= 1'b0;
        end else begin
            data_in_reg <= data_in;
            polarity_reg <= polarity;
        end
    end
    
    // Clock divider by 2 for Manchester encoding
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            clk_div2 <= 1'b0;
        else
            clk_div2 <= ~clk_div2;
    end
    
    // 优化后的Manchester编码逻辑
    // 将组合逻辑放在寄存器前面，减少关键路径延迟
    wire manchester_logic;
    assign manchester_logic = polarity_reg ? (data_in_reg ^ ~clk_div2) : (data_in_reg ^ clk_div2);
    
    // 输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            manchester_out <= 1'b0;
        end else begin
            manchester_out <= manchester_logic;
        end
    end
endmodule