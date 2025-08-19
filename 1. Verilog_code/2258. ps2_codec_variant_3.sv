//SystemVerilog
module ps2_codec (
    input clk_ps2, data,
    output reg [7:0] keycode,
    output reg parity_ok
);
    // 数据移位寄存器
    reg [10:0] shift;
    // 暂存完整的数据帧
    reg [10:0] frame;
    reg frame_ready;
    
    // 接收数据移位处理
    always @(negedge clk_ps2) begin
        shift <= {data, shift[10:1]};
        // 检测一个完整的帧 (当最低位为起始位0时)
        if(shift[0] == 1'b0) begin
            frame <= shift;
            frame_ready <= 1'b1;
        end else begin
            frame_ready <= 1'b0;
        end
    end
    
    // 数据验证与输出处理 - 将处理逻辑移至帧接收后
    always @(posedge clk_ps2) begin
        if(frame_ready) begin
            keycode <= frame[8:1];
            parity_ok <= (^frame[8:1] == frame[9]);
        end
    end
endmodule