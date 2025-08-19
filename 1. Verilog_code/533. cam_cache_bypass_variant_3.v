// 顶层模块
module cam_cache_bypass #(
    parameter WIDTH = 16,
    parameter DEPTH = 128
)(
    input clk,
    input write_en,
    input [$clog2(DEPTH)-1:0] write_addr,
    input [WIDTH-1:0] write_data,
    input [WIDTH-1:0] search_data,
    output hit,
    output [WIDTH-1:0] cache_out
);
    // 内部信号定义
    wire [WIDTH-1:0] last_matched;
    wire cam_hit;
    
    // 内存管理子模块实例化
    cam_memory #(
        .WIDTH(WIDTH),
        .DEPTH(DEPTH)
    ) memory_unit (
        .clk(clk),
        .write_en(write_en),
        .write_addr(write_addr),
        .write_data(write_data),
        .search_data(search_data),
        .hit(cam_hit),
        .matched_data(last_matched)
    );
    
    // 输出控制子模块实例化
    output_controller #(
        .WIDTH(WIDTH)
    ) output_unit (
        .clk(clk),
        .hit_in(cam_hit),
        .matched_data(last_matched),
        .hit_out(hit),
        .cache_out(cache_out)
    );
endmodule

// 内存管理子模块
module cam_memory #(
    parameter WIDTH = 16,
    parameter DEPTH = 128
)(
    input clk,
    input write_en,
    input [$clog2(DEPTH)-1:0] write_addr,
    input [WIDTH-1:0] write_data,
    input [WIDTH-1:0] search_data,
    output reg hit,
    output reg [WIDTH-1:0] matched_data
);
    // CAM存储器
    reg [WIDTH-1:0] cam_array [0:DEPTH-1];
    
    // 写入操作逻辑
    always @(posedge clk) begin
        if (write_en)
            cam_array[write_addr] <= write_data;
    end
    
    // 搜索操作逻辑 - 流水线优化
    integer i;
    always @(posedge clk) begin
        hit <= 0;
        for(i=0; i<DEPTH; i=i+1) begin
            if(cam_array[i] == search_data) begin
                hit <= 1;
                matched_data <= cam_array[i];
            end
        end
    end
endmodule

// 输出控制子模块
module output_controller #(
    parameter WIDTH = 16
)(
    input clk,
    input hit_in,
    input [WIDTH-1:0] matched_data,
    output reg hit_out,
    output reg [WIDTH-1:0] cache_out
);
    // 寄存hit信号
    always @(posedge clk) begin
        hit_out <= hit_in;
    end
    
    // 输出数据控制
    always @(posedge clk) begin
        if (hit_in)
            cache_out <= matched_data;
        else
            cache_out <= {WIDTH{1'b0}};
    end
endmodule