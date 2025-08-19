//SystemVerilog
module DualBufRecovery #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire async_rst,
    input wire [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);
    reg [WIDTH-1:0] buf1, buf2;
    reg [WIDTH-1:0] match_buf1_buf2, match_buf1_din, match_buf2_din;
    
    always @(posedge clk or posedge async_rst) begin
        if (async_rst) begin
            buf1 <= {WIDTH{1'b0}};
            buf2 <= {WIDTH{1'b0}};
            dout <= {WIDTH{1'b0}};
            match_buf1_buf2 <= {WIDTH{1'b0}};
            match_buf1_din <= {WIDTH{1'b0}};
            match_buf2_din <= {WIDTH{1'b0}};
        end
        else begin
            // 更新缓冲区
            buf1 <= din;
            buf2 <= buf1;
            
            // 计算匹配位
            match_buf1_buf2 <= buf1 & buf2;
            match_buf1_din <= buf1 & din;
            match_buf2_din <= buf2 & din;
            
            // 计算输出
            dout <= match_buf1_buf2 | match_buf1_din | match_buf2_din;
        end
    end
endmodule