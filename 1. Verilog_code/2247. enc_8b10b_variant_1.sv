//SystemVerilog
module enc_8b10b #(parameter K=0) (
    input [7:0] din,
    output reg [9:0] dout,
    input rd_in,
    output reg rd_out
);
    reg [5:0] disparity;
    wire [5:0] rd_new;
    wire c_in = rd_in;
    
    // 简化的并行前缀加法器实现
    wire [5:0] carries;
    
    // 直接计算进位，避免多级嵌套逻辑
    assign carries[0] = c_in;
    assign carries[1] = disparity[0] & c_in;
    assign carries[2] = (disparity[1] & disparity[0] & c_in) | (disparity[1] & carries[1]);
    assign carries[3] = (disparity[2] & carries[2]);
    assign carries[4] = (disparity[3] & disparity[2] & carries[2]) | (disparity[3] & carries[3]);
    assign carries[5] = (disparity[4] & carries[4]);
    
    // 计算新的运行差异
    assign rd_new = disparity ^ {carries[4:0], c_in};
    
    // K码和数据输入的组合
    wire [8:0] k_din = {K, din};
    
    always @(*) begin
        // 默认值设置
        disparity = 6'd0;
        rd_out = rd_in;
        dout = 10'b0101010101; // 默认代码
        
        case(k_din)
            9'b100011100: begin
                dout = 10'b0011111010;
                rd_out = ~rd_in; // 简化表达式：(rd_in <= 0) 等价于 ~rd_in
            end
            9'b010101010: begin
                dout = 10'b1010010111;
                disparity = 6'd2;
                rd_out = rd_new[5];
            end
            9'b000000000: begin
                dout = 10'b0101010101;
                // disparity 和 rd_out 保持默认值
            end
            9'b011111111: begin
                dout = 10'b1010101010;
                // disparity 和 rd_out 保持默认值
            end
            default: begin
                // 使用默认值
            end
        endcase
    end
endmodule