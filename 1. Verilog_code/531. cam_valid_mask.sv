module cam_valid_mask #(parameter WIDTH=12, DEPTH=64)(
    input clk,
    input write_en,                       // 添加写入使能
    input [$clog2(DEPTH)-1:0] write_addr, // 添加写入地址
    input [WIDTH-1:0] write_data,         // 添加写入数据
    input [WIDTH-1:0] data_in,
    input [DEPTH-1:0] valid_mask,
    output [DEPTH-1:0] match_lines
);
    reg [WIDTH-1:0] cam_table [0:DEPTH-1];
    wire [DEPTH-1:0] raw_matches;
    
    // 添加写入逻辑
    always @(posedge clk) begin
        if (write_en)
            cam_table[write_addr] <= write_data;
    end
    
    // 修改数组比较操作
    genvar i;
    generate
        for(i=0; i<DEPTH; i=i+1) begin : gen_match
            assign raw_matches[i] = (cam_table[i] == data_in);
        end
    endgenerate
    
    assign match_lines = raw_matches & valid_mask;
endmodule