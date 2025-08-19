//SystemVerilog
// 顶层模块
module ProgDelayLatch #(parameter DW=8) (
    input clk,
    input [DW-1:0] din,
    input [3:0] delay,
    output [DW-1:0] dout
);

    // 内部信号定义
    wire [DW-1:0] delay_line_out [0:15];
    
    // 实例化延迟线子模块
    DelayLine #(
        .DW(DW)
    ) delay_line_inst (
        .clk(clk),
        .din(din),
        .delay_line_out(delay_line_out)
    );
    
    // 实例化输出选择子模块
    OutputSelector #(
        .DW(DW)
    ) output_selector_inst (
        .delay_line_out(delay_line_out),
        .delay(delay),
        .dout(dout)
    );

endmodule

// 延迟线子模块
module DelayLine #(parameter DW=8) (
    input clk,
    input [DW-1:0] din,
    output reg [DW-1:0] delay_line_out [0:15]
);

    // 使用移位寄存器实现延迟线
    genvar i;
    generate
        for(i=0; i<16; i=i+1) begin : delay_chain
            if(i == 0) begin
                always @(posedge clk) begin
                    delay_line_out[i] <= din;
                end
            end else begin
                always @(posedge clk) begin
                    delay_line_out[i] <= delay_line_out[i-1];
                end
            end
        end
    endgenerate

endmodule

// 输出选择子模块
module OutputSelector #(parameter DW=8) (
    input [DW-1:0] delay_line_out [0:15],
    input [3:0] delay,
    output reg [DW-1:0] dout
);

    // 使用查找表实现输出选择
    always @(*) begin
        case(delay)
            4'd0: dout = delay_line_out[0];
            4'd1: dout = delay_line_out[1];
            4'd2: dout = delay_line_out[2];
            4'd3: dout = delay_line_out[3];
            4'd4: dout = delay_line_out[4];
            4'd5: dout = delay_line_out[5];
            4'd6: dout = delay_line_out[6];
            4'd7: dout = delay_line_out[7];
            4'd8: dout = delay_line_out[8];
            4'd9: dout = delay_line_out[9];
            4'd10: dout = delay_line_out[10];
            4'd11: dout = delay_line_out[11];
            4'd12: dout = delay_line_out[12];
            4'd13: dout = delay_line_out[13];
            4'd14: dout = delay_line_out[14];
            4'd15: dout = delay_line_out[15];
            default: dout = delay_line_out[0];
        endcase
    end

endmodule