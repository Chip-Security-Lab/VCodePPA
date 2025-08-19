module cam_cache_bypass #(parameter WIDTH=16, DEPTH=128)(
    input clk,
    input write_en,                       // 添加写入使能
    input [$clog2(DEPTH)-1:0] write_addr, // 添加写入地址
    input [WIDTH-1:0] write_data,         // 添加写入数据
    input [WIDTH-1:0] search_data,
    output reg hit,
    output reg [WIDTH-1:0] cache_out
);
    reg [WIDTH-1:0] cam_array [0:DEPTH-1];
    reg [WIDTH-1:0] last_matched;
    
    // 添加写入逻辑
    always @(posedge clk) begin
        if (write_en)
            cam_array[write_addr] <= write_data;
    end
    
    // 修改搜索和输出逻辑
    integer i;
    always @(posedge clk) begin
        hit <= 0;
        for(i=0; i<DEPTH; i=i+1) begin
            if(cam_array[i] == search_data) begin
                hit <= 1;
                last_matched <= cam_array[i];
            end
        end
        
        // 修改输出逻辑，避免使用高阻态
        if (hit)
            cache_out <= last_matched;
        else
            cache_out <= {WIDTH{1'b0}}; // 使用0代替高阻态
    end
endmodule