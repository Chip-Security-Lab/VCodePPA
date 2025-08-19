module cam_cache_bypass #(parameter WIDTH=16, DEPTH=128)(
    input clk,
    input write_en,
    input [$clog2(DEPTH)-1:0] write_addr,
    input [WIDTH-1:0] write_data,
    input [WIDTH-1:0] search_data,
    output reg hit,
    output reg [WIDTH-1:0] cache_out
);
    // 存储器阵列
    reg [WIDTH-1:0] cam_array [0:DEPTH-1];
    
    // 匹配结果寄存器和标志
    reg [DEPTH-1:0] match_flags;
    reg [$clog2(DEPTH)-1:0] match_addr;
    reg has_match;
    
    // 写入逻辑 - 保持不变
    always @(posedge clk) begin
        if (write_en)
            cam_array[write_addr] <= write_data;
    end
    
    // 匹配逻辑 - 修改为两阶段流水线以提高时序性能
    integer i;
    always @(posedge clk) begin
        // 第一阶段：并行比较所有条目
        i = 0;
        while(i < DEPTH) begin
            match_flags[i] <= (cam_array[i] == search_data);
            i = i + 1;
        end
        
        // 第二阶段：优先编码器查找第一个匹配
        has_match <= |match_flags;
        match_addr <= 0;
        i = DEPTH-1;
        while(i >= 0) begin
            if(match_flags[i])
                match_addr <= i[$clog2(DEPTH)-1:0];
            i = i - 1;
        end
        
        // 输出逻辑
        hit <= has_match;
        cache_out <= has_match ? cam_array[match_addr] : {WIDTH{1'b0}};
    end
endmodule