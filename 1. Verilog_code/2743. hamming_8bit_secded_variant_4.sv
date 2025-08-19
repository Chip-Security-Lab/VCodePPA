//SystemVerilog
module hamming_8bit_secded(
    input clk,
    input rst_n,
    // 输入接口 - Valid-Ready握手
    input [7:0] data_in,
    input data_valid,
    output data_ready,
    // 输出接口 - Valid-Ready握手
    output [12:0] code_out,
    output code_valid,
    input code_ready
);

    // 内部寄存器
    reg [7:0] data_reg;
    reg [12:0] code_reg;
    reg valid_reg;
    
    // 组合逻辑部分
    wire [3:0] parity;
    wire overall_parity;
    wire [12:0] code_next;
    wire data_ready_comb;
    wire code_valid_comb;
    
    // 握手逻辑 - 纯组合
    assign data_ready_comb = ~valid_reg | (valid_reg & code_ready);
    assign code_valid_comb = valid_reg;
    assign data_ready = data_ready_comb;
    assign code_valid = code_valid_comb;
    assign code_out = code_reg;
    
    // 奇偶校验计算 - 纯组合
    assign parity[0] = ^(data_reg & 8'b10101010);
    assign parity[1] = ^(data_reg & 8'b11001100);
    assign parity[2] = ^(data_reg & 8'b11110000);
    assign parity[3] = ^data_reg;
    
    // 总体奇偶校验 - 纯组合
    assign overall_parity = ^{parity, data_reg};
    
    // 汉明码组装 - 纯组合
    assign code_next = {overall_parity,
                    data_reg[7:4],
                    parity[3],
                    data_reg[3:1],
                    parity[2],
                    data_reg[0],
                    parity[1],
                    parity[0]};
    
    // 时序逻辑部分
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            data_reg <= 8'b0;
            code_reg <= 13'b0;
            valid_reg <= 1'b0;
        end else begin
            // 数据接收逻辑
            if (data_valid && data_ready_comb) begin
                data_reg <= data_in;
                valid_reg <= 1'b1;
            end else if (valid_reg && code_ready) begin
                valid_reg <= 1'b0;
            end
            
            // 代码更新逻辑
            if (valid_reg && ~(valid_reg && code_ready)) begin
                code_reg <= code_next;
            end
        end
    end
endmodule