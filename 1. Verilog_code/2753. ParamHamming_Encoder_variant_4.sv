//SystemVerilog
module ParamHamming_Encoder #(
    parameter DATA_WIDTH = 8
)(
    input clk,
    input en,
    input [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH+4:0] code_out // 简化位宽计算
);
    // 计算校验位数量，简化为固定值4
    parameter PARITY_BITS = 4;
    
    // 寄存输入数据
    reg [DATA_WIDTH-1:0] data_reg;
    
    // 校验位寄存器
    reg [PARITY_BITS-1:0] parity;
    
    // 组合信号用于计算校验位
    wire [PARITY_BITS-1:0] parity_calc;
    
    // 寄存输入数据
    always @(posedge clk) begin
        if(en) begin
            data_reg <= data_in;
        end
    end
    
    // 计算每个校验位 - 组合逻辑
    genvar i, j;
    generate
        for(i=0; i<PARITY_BITS; i=i+1) begin: parity_gen
            wire [DATA_WIDTH-1:0] masked_bits;
            
            for(j=0; j<DATA_WIDTH; j=j+1) begin: mask_bits
                assign masked_bits[j] = ((j+1) & (1 << i)) ? data_in[j] : 1'b0;
            end
            
            assign parity_calc[i] = ^masked_bits;
        end
    endgenerate
    
    // 寄存校验位结果
    always @(posedge clk) begin
        if(en) begin
            parity <= parity_calc;
        end
    end
    
    // 输出校验位到特定位置
    always @(posedge clk) begin
        if(en) begin
            code_out[0] <= parity_calc[0];
            code_out[1] <= parity_calc[1];
            code_out[3] <= parity_calc[2];
            code_out[7] <= parity_calc[3];
        end
    end
    
    // 将数据位插入到输出编码中的非校验位位置
    integer idx;
    always @(posedge clk) begin
        if(en) begin
            idx = 0;
            for(integer i=0; i<DATA_WIDTH+5; i=i+1) begin
                if(i != 0 && i != 1 && i != 3 && i != 7) begin
                    if(idx < DATA_WIDTH) begin
                        code_out[i] <= data_in[idx];
                        idx = idx + 1;
                    end
                end
            end
        end
    end
    
endmodule