module cam_async_reset #(parameter WIDTH=4, DEPTH=8)(
    input clk,
    input async_rst,
    input write_en,
    input [$clog2(DEPTH)-1:0] write_addr,
    input [WIDTH-1:0] write_data,
    input [WIDTH-1:0] search_data,
    output reg [DEPTH-1:0] match_lines
);
    // CAM存储
    reg [WIDTH-1:0] cam_entries [0:DEPTH-1];
    
    // 使用指定的比较结果缓存，提高性能并降低动态功耗
    reg [WIDTH-1:0] last_search_data;
    reg [DEPTH-1:0] match_reg;
    reg search_valid;
    
    // 异步复位逻辑
    integer i;
    always @(posedge clk or posedge async_rst) begin
        if(async_rst) begin
            // 复位所有条目和缓存状态
            for(i=0; i<DEPTH; i=i+1)
                cam_entries[i] <= {WIDTH{1'b0}};
            
            last_search_data <= {WIDTH{1'b0}};
            search_valid <= 1'b0;
            match_reg <= {DEPTH{1'b0}};
        end else begin
            // 写入操作
            if (write_en) begin
                cam_entries[write_addr] <= write_data;
                // 写入会使缓存失效
                search_valid <= 1'b0;
            end
            
            // 更新搜索数据缓存
            last_search_data <= search_data;
            
            // 当搜索数据变化或缓存无效时，更新比较结果
            if (search_data != last_search_data || !search_valid) begin
                search_valid <= 1'b1;
                
                // 进行比较操作
                for(i=0; i<DEPTH; i=i+1) begin
                    match_reg[i] <= (cam_entries[i] == search_data);
                end
            end
        end
    end
    
    // 输出比较结果
    always @(*) begin
        match_lines = match_reg;
    end
endmodule