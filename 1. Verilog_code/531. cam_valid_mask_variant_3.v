module cam_valid_mask #(parameter WIDTH=12, DEPTH=64)(
    input clk,
    input write_en,                       
    input [$clog2(DEPTH)-1:0] write_addr, 
    input [WIDTH-1:0] write_data,         
    input [WIDTH-1:0] data_in,
    input [DEPTH-1:0] valid_mask,
    output [DEPTH-1:0] match_lines
);
    // 内存表声明
    reg [WIDTH-1:0] cam_table [0:DEPTH-1];
    wire [DEPTH-1:0] raw_matches;
    
    // 写入逻辑 - 独立always块
    always @(posedge clk) begin
        if (write_en)
            cam_table[write_addr] <= write_data;
    end
    
    // 比较逻辑模块 - 使用参数化方法改进
    genvar i;
    generate
        for(i=0; i<DEPTH; i=i+1) begin : gen_match
            // 声明用于比较的信号
            wire match_result;
            
            // 实例化比较器模块
            cam_comparator #(
                .WIDTH(WIDTH)
            ) comparator_inst (
                .data_a(cam_table[i]),
                .data_b(data_in),
                .match(match_result)
            );
            
            // 分配匹配结果
            assign raw_matches[i] = match_result;
        end
    endgenerate
    
    // 掩码逻辑 - 独立模块
    assign match_lines = raw_matches & valid_mask;
endmodule

// 比较器子模块 - 封装借位减法器逻辑
module cam_comparator #(parameter WIDTH=12)(
    input [WIDTH-1:0] data_a,
    input [WIDTH-1:0] data_b,
    output match
);
    // 声明用于借位减法的信号
    wire [WIDTH-1:0] diff;
    wire [WIDTH:0] borrow;
    
    // 初始无借位
    assign borrow[0] = 1'b0;
    
    // 实现借位减法器
    genvar j;
    generate
        for(j=0; j<WIDTH; j=j+1) begin : gen_sub_bit
            assign diff[j] = data_a[j] ^ data_b[j] ^ borrow[j];
            assign borrow[j+1] = (~data_a[j] & data_b[j]) | 
                                (~data_a[j] & borrow[j]) | 
                                (data_b[j] & borrow[j]);
        end
    endgenerate
    
    // 如果差值为0且最终无借位，则匹配
    assign match = (diff == {WIDTH{1'b0}}) && (borrow[WIDTH] == 1'b0);
endmodule