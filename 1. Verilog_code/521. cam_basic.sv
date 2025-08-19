module cam_basic #(parameter WIDTH=8, DEPTH=16)(
    input clk,
    input write_en,                         // 添加写入使能
    input [$clog2(DEPTH)-1:0] write_addr,   // 添加写入地址
    input [WIDTH-1:0] write_data,           // 添加写入数据
    input [WIDTH-1:0] data_in,
    output reg [DEPTH-1:0] match_flags
);
    reg [WIDTH-1:0] cam_table [0:DEPTH-1];
    
    // 添加写入逻辑
    always @(posedge clk) begin
        if (write_en)
            cam_table[write_addr] <= write_data;
    end
    
    // 将int改为integer (合成工具支持)
    integer i;
    always @(posedge clk) begin
        for(i=0; i<DEPTH; i=i+1)
            match_flags[i] <= (cam_table[i] == data_in);
    end
endmodule