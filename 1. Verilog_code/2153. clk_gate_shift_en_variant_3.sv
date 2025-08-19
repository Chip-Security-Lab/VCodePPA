//SystemVerilog
///////////////////////////////////////////
///////////////////////////////////////////
module clk_gate_shift_en #(parameter DEPTH=3) (
    input clk, en, in,
    output reg [DEPTH-1:0] out
);
    // 查找表用于优化移位操作
    reg [DEPTH-1:0] lut_shift[0:1][0:DEPTH-1];
    
    // 初始化查找表
    integer i, j;
    initial begin
        for (i = 0; i < 2; i = i + 1) begin
            for (j = 0; j < DEPTH; j = j + 1) begin
                if (i == 0) begin
                    if (j > 0) begin
                        lut_shift[i][j] = (1 << (j-1));
                    end else begin
                        lut_shift[i][j] = 0;
                    end
                end else begin
                    if (j > 0) begin
                        lut_shift[i][j] = (1 << (j-1));
                    end else begin
                        lut_shift[i][j] = 1;
                    end
                end
            end
        end
    end
    
    // 减法器辅助变量
    reg [DEPTH-1:0] next_out;
    reg [DEPTH-1:0] shift_result;
    
    // 查找表辅助的移位计算
    always @(*) begin
        shift_result = 0;
        for (j = 0; j < DEPTH; j = j + 1) begin
            if (out[j]) begin
                shift_result = shift_result | lut_shift[in][j];
            end
        end
        next_out = shift_result;
    end
    
    // 寄存器更新逻辑
    always @(posedge clk) begin
        if(en) begin
            out <= next_out;
        end
    end
endmodule