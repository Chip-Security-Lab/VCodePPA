module crc_hybrid #(parameter WIDTH=32)(
    input clk, en,
    input [WIDTH-1:0] data,
    output reg [31:0] crc
);
    // 简化实现，仅处理32位数据
    // 对于大于32位的宽度，这里使用简化计算
    
    reg [31:0] temp;
    wire [31:0] data_32 = data[31:0];
    
    // 为WIDTH > 32的情况提供一个简化计算
    wire [31:0] result = (WIDTH > 32) ? 
                       {data_32[30:0], 1'b0} ^ 
                       (data_32[31] ? 32'h04C11DB7 : 0) : 
                       data_32;
    
    always @(posedge clk) begin
        if (en) begin
            temp <= data_32;  // 并行处理高32位
            crc <= result;
        end
    end
endmodule