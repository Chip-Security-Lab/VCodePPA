module cam_cache_bypass #(parameter WIDTH=16, DEPTH=128)(
    input clk,
    input write_en,                       
    input [$clog2(DEPTH)-1:0] write_addr, 
    input [WIDTH-1:0] write_data,         
    input [WIDTH-1:0] search_data,
    output reg hit,
    output reg [WIDTH-1:0] cache_out
);
    reg [WIDTH-1:0] cam_array [0:DEPTH-1];
    
    integer i;
    reg hit_temp;
    reg [WIDTH-1:0] last_matched_temp;

    always @(posedge clk) begin
        // 写入逻辑
        if (write_en)
            cam_array[write_addr] <= write_data;
            
        // 搜索逻辑
        hit_temp <= 0;
        last_matched_temp <= {WIDTH{1'b0}};
        for(i=0; i<DEPTH; i=i+1) begin
            if(cam_array[i] == search_data) begin
                hit_temp <= 1;
                last_matched_temp <= cam_array[i];
            end
        end
        
        // 输出逻辑
        hit <= hit_temp;
        cache_out <= hit_temp ? last_matched_temp : {WIDTH{1'b0}};
    end
endmodule