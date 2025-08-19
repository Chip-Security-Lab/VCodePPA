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
    reg [DATA_WIDTH-1:0] data_reg;
    reg [PARITY_BITS-1:0] parity;
    integer i, j, mask;
    
    always @(posedge clk) begin
        if(en) begin
            data_reg <= data_in;
            
            // 计算校验位
            for(i=0; i<PARITY_BITS; i=i+1) begin
                mask = (1 << i);
                parity[i] = 0;
                for(j=0; j<DATA_WIDTH; j=j+1) begin
                    if((j+1) & mask) 
                        parity[i] = parity[i] ^ data_in[j];
                end
            end
            
            // 组合输出
            code_out[DATA_WIDTH+4:DATA_WIDTH+1] <= data_reg;
            code_out[0] <= parity[0];
            code_out[1] <= parity[1];
            code_out[3] <= parity[2];
            code_out[7] <= parity[3];
            
            // 插入数据位
            j = 0;
            for(i=0; i<DATA_WIDTH+5; i=i+1) begin
                if(i != 0 && i != 1 && i != 3 && i != 7) begin
                    if(j < DATA_WIDTH) begin
                        code_out[i] <= data_reg[j];
                        j = j + 1;
                    end
                end
            end
        end
    end
endmodule