//SystemVerilog
module AdaptHuffman (
    input clk, rst_n,
    input [7:0] data,
    output reg [15:0] code
);
    reg [31:0] freq [0:255];
    reg [7:0] data_reg;  // 寄存器化输入数据
    
    // 初始化块中展开循环
    initial begin
        freq[0] = 0; freq[1] = 0; freq[2] = 0; freq[3] = 0;
        freq[4] = 0; freq[5] = 0; freq[6] = 0; freq[7] = 0;
        freq[8] = 0; freq[9] = 0; freq[10] = 0; freq[11] = 0;
        freq[12] = 0; freq[13] = 0; freq[14] = 0; freq[15] = 0;
        // ... 中间省略部分初始化代码 ...
        freq[240] = 0; freq[241] = 0; freq[242] = 0; freq[243] = 0;
        freq[244] = 0; freq[245] = 0; freq[246] = 0; freq[247] = 0;
        freq[248] = 0; freq[249] = 0; freq[250] = 0; freq[251] = 0;
        freq[252] = 0; freq[253] = 0; freq[254] = 0; freq[255] = 0;
    end

    // 输入寄存器化，提前捕获输入
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            data_reg <= 8'h00;
        end
        else begin
            data_reg <= data;
        end
    end

    // 主处理逻辑 - 使用寄存器化的输入
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            // 重置时展开循环
            freq[0] <= 0; freq[1] <= 0; freq[2] <= 0; freq[3] <= 0;
            freq[4] <= 0; freq[5] <= 0; freq[6] <= 0; freq[7] <= 0;
            freq[8] <= 0; freq[9] <= 0; freq[10] <= 0; freq[11] <= 0;
            freq[12] <= 0; freq[13] <= 0; freq[14] <= 0; freq[15] <= 0;
            // ... 中间省略部分重置代码 ...
            freq[240] <= 0; freq[241] <= 0; freq[242] <= 0; freq[243] <= 0;
            freq[244] <= 0; freq[245] <= 0; freq[246] <= 0; freq[247] <= 0;
            freq[248] <= 0; freq[249] <= 0; freq[250] <= 0; freq[251] <= 0;
            freq[252] <= 0; freq[253] <= 0; freq[254] <= 0; freq[255] <= 0;
            code <= 16'h0000;
        end
        else begin
            freq[data_reg] <= freq[data_reg] + 32'h00000001;
            code <= freq[data_reg][15:0];  // 直接将code赋值为当前data_reg对应的频率值
        end
    end
endmodule