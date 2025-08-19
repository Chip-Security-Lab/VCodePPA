module cam_basic #(parameter WIDTH=8, DEPTH=16)(
    input clk,
    input write_en,
    input [$clog2(DEPTH)-1:0] write_addr,
    input [WIDTH-1:0] write_data,
    input [WIDTH-1:0] data_in,
    output reg [DEPTH-1:0] match_flags
);
    reg [WIDTH-1:0] cam_table [0:DEPTH-1];
    wire [WIDTH-1:0] data_in_comp;
    wire [WIDTH-1:0] diff [0:DEPTH-1];
    wire [DEPTH-1:0] match_temp;
    
    // 提前计算补码，减少关键路径
    assign data_in_comp = ~data_in + 1'b1;
    
    // 使用流水线结构优化比较逻辑
    genvar j;
    generate
        for(j=0; j<DEPTH; j=j+1) begin: COMPARE
            // 将加法器输出分为高低位，减少进位链长度
            wire [WIDTH/2-1:0] diff_high, diff_low;
            wire carry;
            
            // 低位加法
            assign {carry, diff_low} = cam_table[j][WIDTH/2-1:0] + data_in_comp[WIDTH/2-1:0];
            // 高位加法
            assign diff_high = cam_table[j][WIDTH-1:WIDTH/2] + data_in_comp[WIDTH-1:WIDTH/2] + carry;
            
            // 合并结果并检测零
            assign diff[j] = {diff_high, diff_low};
            assign match_temp[j] = ~(|diff_high) & ~(|diff_low);
        end
    endgenerate
    
    always @(posedge clk) begin
        if (write_en)
            cam_table[write_addr] <= write_data;
        match_flags <= match_temp;
    end
endmodule