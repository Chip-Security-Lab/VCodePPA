//SystemVerilog
module crc_hybrid #(parameter WIDTH=32)(
    input clk, en,
    input [WIDTH-1:0] data,
    output reg [31:0] crc
);

    reg [31:0] temp;
    wire [31:0] data_32 = data[31:0];
    
    // 并行前缀减法器实现
    wire [31:0] gen[31:0];
    wire [31:0] prop[31:0];
    wire [31:0] carry[31:0];
    
    // 生成和传播信号
    generate
        genvar i;
        for (i = 0; i < 32; i = i + 1) begin : prefix_network
            assign gen[i] = data_32[i] & 1'b1;
            assign prop[i] = data_32[i] ^ 1'b1;
        end
    endgenerate
    
    // 并行前缀树
    generate
        for (i = 0; i < 32; i = i + 1) begin : prefix_tree
            if (i == 0) begin
                assign carry[i] = gen[i];
            end else begin
                assign carry[i] = gen[i] | (prop[i] & carry[i-1]);
            end
        end
    endgenerate
    
    // 最终结果计算
    wire [31:0] result = (WIDTH > 32) ? 
                        {data_32[30:0], 1'b0} ^ 
                        (data_32[31] ? 32'h04C11DB7 : 0) : 
                        data_32;
    
    always @(posedge clk) begin
        if (en) begin
            temp <= data_32;
            crc <= result;
        end
    end
endmodule