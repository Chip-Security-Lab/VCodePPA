//SystemVerilog
module prog_freq_divider #(parameter COUNTER_WIDTH = 16) (
    input  wire clk_i,
    input  wire rst_i,
    input  wire [COUNTER_WIDTH-1:0] divisor,
    input  wire update,
    output reg  clk_o
);
    reg [COUNTER_WIDTH-1:0] counter;
    reg [COUNTER_WIDTH-1:0] divisor_reg;
    
    // 更新分频系数
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            divisor_reg <= {COUNTER_WIDTH{1'b0}};
        end else if (update) begin
            divisor_reg <= divisor;
        end
    end
    
    // 计数器逻辑
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            counter <= {COUNTER_WIDTH{1'b0}};
        end else if (counter >= divisor_reg - 1) begin
            counter <= {COUNTER_WIDTH{1'b0}};
        end else begin
            counter <= counter + 1'b1;
        end
    end
    
    // 输出时钟生成逻辑
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            clk_o <= 1'b0;
        end else if (counter >= divisor_reg - 1) begin
            clk_o <= ~clk_o;
        end
    end
endmodule