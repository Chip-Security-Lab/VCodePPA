module cam_clock_gated #(parameter WIDTH=8, DEPTH=32)(
    input clk,
    input search_en,
    input write_en,                         // 添加写入使能
    input [$clog2(DEPTH)-1:0] write_addr,   // 添加写入地址
    input [WIDTH-1:0] write_data,           // 添加写入数据
    input [WIDTH-1:0] data_in,
    output reg [DEPTH-1:0] match_flags
);
    reg [WIDTH-1:0] entries [0:DEPTH-1];
    
    // 移除错误的时钟门控 (会导致毛刺)
    // 原代码: assign gated_clk = clk & search_en;
    
    // 添加写入逻辑
    always @(posedge clk) begin
        if (write_en)
            entries[write_addr] <= write_data;
    end
    
    // 使用使能信号代替时钟门控
    integer i;
    always @(posedge clk) begin
        if (search_en) begin
            for(i=0; i<DEPTH; i=i+1)
                match_flags[i] <= (entries[i] == data_in);
        end
    end
endmodule