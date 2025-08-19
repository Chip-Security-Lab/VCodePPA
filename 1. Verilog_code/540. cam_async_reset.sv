module cam_async_reset #(parameter WIDTH=4, DEPTH=8)(
    input clk,
    input async_rst,
    input write_en,                       // 添加写入使能
    input [$clog2(DEPTH)-1:0] write_addr, // 添加写入地址
    input [WIDTH-1:0] write_data,         // 添加写入数据
    input [WIDTH-1:0] search_data,        // 添加搜索数据
    output [DEPTH-1:0] match_lines        // 添加匹配输出
);
    // 添加CAM存储
    reg [WIDTH-1:0] cam_entries [0:DEPTH-1];
    
    // 修正异步复位逻辑
    integer i;
    always @(posedge clk or posedge async_rst) begin
        if(async_rst) begin
            // 复位所有条目
            for(i=0; i<DEPTH; i=i+1)
                cam_entries[i] <= {WIDTH{1'b0}};
        end else if (write_en) begin
            // 写入操作
            cam_entries[write_addr] <= write_data;
        end
    end
    
    // 添加搜索逻辑
    genvar j;
    generate
        for(j=0; j<DEPTH; j=j+1) begin : gen_match
            assign match_lines[j] = (cam_entries[j] == search_data);
        end
    endgenerate
endmodule