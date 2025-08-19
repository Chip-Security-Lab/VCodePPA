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
    
    // 预计算比较结果，减少关键路径延迟
    reg [DEPTH-1:0] match_results;
    integer j;
    
    // 分段比较，平衡组合逻辑路径
    always @(*) begin
        for(j=0; j<DEPTH; j=j+1) begin
            // 将大型比较操作分解为分段比较，减少比较器深度
            match_results[j] = (entries[j][WIDTH-1:WIDTH/2] == data_in[WIDTH-1:WIDTH/2]) && 
                              (entries[j][WIDTH/2-1:0] == data_in[WIDTH/2-1:0]);
        end
    end
    
    // 写入逻辑优化 - 无变化，已经很简洁
    always @(posedge clk) begin
        if (write_en)
            entries[write_addr] <= write_data;
    end
    
    // 搜索逻辑优化 - 使用预计算的比较结果
    integer i;
    always @(posedge clk) begin
        if (search_en) begin
            for(i=0; i<DEPTH; i=i+1)
                match_flags[i] <= match_results[i];
        end
    end
endmodule