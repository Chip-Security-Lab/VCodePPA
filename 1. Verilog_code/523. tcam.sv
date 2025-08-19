module tcam #(parameter WIDTH=32, DEPTH=64)(
    input clk,
    input write_en,                         // 添加写入使能
    input [$clog2(DEPTH)-1:0] write_addr,   // 添加写入地址
    input [WIDTH-1:0] write_data,           // 添加写入数据
    input [WIDTH-1:0] write_mask,           // 添加写入掩码
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] mask_in,
    output [DEPTH-1:0] hit_lines
);
    reg [WIDTH-1:0] tcam_data [0:DEPTH-1];
    reg [WIDTH-1:0] tcam_mask [0:DEPTH-1];
    
    // 添加写入逻辑
    always @(posedge clk) begin
        if (write_en) begin
            tcam_data[write_addr] <= write_data;
            tcam_mask[write_addr] <= write_mask;
        end
    end
    
    // 使用genvar替代generate语句中的for循环
    genvar i;
    generate
        for(i=0; i<DEPTH; i=i+1) begin : gen_match
            assign hit_lines[i] = ((data_in & tcam_mask[i]) == (tcam_data[i] & tcam_mask[i]));
        end
    endgenerate
endmodule