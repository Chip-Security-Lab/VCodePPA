//SystemVerilog
module shadow_reg_status #(parameter DW=8) (
    input clk, rst, en,
    input [DW-1:0] data_in,
    output reg [DW-1:0] data_out,
    output reg valid
);
    reg [DW-1:0] shadow_reg;
    reg [DW-1:0] adder_result;
    
    // 先行进位加法器相关信号
    wire [DW-1:0] inverted_data_in;
    wire [DW-1:0] p, g;
    wire [DW:0] c;
    
    // 因为我们需要实现等效的减法功能，所以使用取反+1的方式
    // 对data_in取反
    assign inverted_data_in = ~data_in;
    
    // 生成传播信号和生成信号
    assign p = shadow_reg ^ inverted_data_in;
    assign g = shadow_reg & inverted_data_in;
    
    // 进位的初始值为1（因为这是减法的借位实现：取反+1）
    assign c[0] = 1'b1;
    
    // 使用先行进位加法器算法计算进位
    genvar i;
    generate
        for(i = 0; i < DW; i = i + 1) begin : carry_lookahead
            assign c[i+1] = g[i] | (p[i] & c[i]);
        end
    endgenerate
    
    // 计算最终结果
    always @(*) begin
        for(integer j = 0; j < DW; j = j + 1) begin
            adder_result[j] = p[j] ^ c[j];
        end
    end
    
    // 时序逻辑保持不变
    always @(posedge clk) begin
        if(rst) begin
            data_out <= {DW{1'b0}};
            valid <= 1'b0;
            shadow_reg <= {DW{1'b0}};
        end
        else if(en) begin
            shadow_reg <= data_in;
            valid <= 1'b0;
        end else begin
            data_out <= adder_result; // 使用先行进位加法器的结果
            valid <= 1'b1;
        end
    end
endmodule