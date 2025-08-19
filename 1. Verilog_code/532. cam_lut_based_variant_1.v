module cam_lut_based #(
    parameter WIDTH = 4,
    parameter DEPTH = 8
)(
    input [WIDTH-1:0] search_key,
    output [DEPTH-1:0] hit_vector
);
    // 内部信号
    wire valid_key;
    wire [DEPTH-1:0] decoded_output;
    
    // 子模块实例化
    key_validator #(
        .WIDTH(WIDTH),
        .DEPTH(DEPTH)
    ) validator_inst (
        .search_key(search_key),
        .valid_key(valid_key)
    );
    
    key_decoder #(
        .WIDTH(WIDTH),
        .DEPTH(DEPTH)
    ) decoder_inst (
        .search_key(search_key),
        .valid_key(valid_key),
        .decoded_output(decoded_output)
    );
    
    // 直接连接解码后的输出到hit_vector
    assign hit_vector = decoded_output;
    
endmodule

// 子模块：键值有效性验证器
module key_validator #(
    parameter WIDTH = 4,
    parameter DEPTH = 8
)(
    input [WIDTH-1:0] search_key,
    output valid_key
);
    // 检查搜索键是否在有效范围内
    assign valid_key = (search_key < DEPTH);
endmodule

// 子模块：键值解码器
module key_decoder #(
    parameter WIDTH = 4,
    parameter DEPTH = 8
)(
    input [WIDTH-1:0] search_key,
    input valid_key,
    output reg [DEPTH-1:0] decoded_output
);
    // 使用参数化生成解码逻辑
    integer i;
    
    always @(*) begin
        // 初始化所有位为0
        for (i = 0; i < DEPTH; i = i + 1) begin
            decoded_output[i] = 1'b0;
        end
        
        // 只在有效键值时设置相应位为1
        if (valid_key) begin
            decoded_output[search_key] = 1'b1;
        end
    end
endmodule