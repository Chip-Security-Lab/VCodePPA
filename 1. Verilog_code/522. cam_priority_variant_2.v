module cam_clock_gated #(parameter WIDTH=8, DEPTH=32)(
    input clk,
    input search_en,
    input write_en,
    input [$clog2(DEPTH)-1:0] write_addr,
    input [WIDTH-1:0] write_data,
    input [WIDTH-1:0] data_in,
    output reg [DEPTH-1:0] match_flags
);
    reg [WIDTH-1:0] entries [0:DEPTH-1];
    wire [WIDTH-1:0] diff [0:DEPTH-1];
    wire [DEPTH-1:0] match_temp;
    
    // 写入逻辑保持不变
    always @(posedge clk) begin
        if (write_en)
            entries[write_addr] <= write_data;
    end
    
    // 条件求和减法器实现
    genvar i;
    generate
        for(i=0; i<DEPTH; i=i+1) begin: SUBTRACTOR
            // 条件求和减法算法实现
            wire [WIDTH-1:0] data_in_comp = ~data_in + 1'b1;  // 取反加1得到补码
            wire [WIDTH:0] sum_temp = entries[i] + data_in_comp;  // 带进位位的加法
            assign diff[i] = sum_temp[WIDTH-1:0];  // 取低WIDTH位作为差值
            assign match_temp[i] = ~(|sum_temp[WIDTH-1:0]);  // 所有位都为0时匹配
        end
    endgenerate
    
    // 使用使能信号控制输出
    always @(posedge clk) begin
        if (search_en)
            match_flags <= match_temp;
    end
endmodule