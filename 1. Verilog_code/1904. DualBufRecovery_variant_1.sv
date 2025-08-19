//SystemVerilog
module DualBufRecovery #(parameter WIDTH=8) (
    input clk, async_rst,
    input [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);
    reg [WIDTH-1:0] buf1, buf2;
    reg [WIDTH-1:0] match_din_buf1, match_din_buf2, match_buf1_buf2;
    reg [WIDTH-1:0] recovery_data;
    
    // 缓冲区更新逻辑
    always @(posedge clk or posedge async_rst) begin
        if (async_rst) begin
            buf1 <= {WIDTH{1'b0}};
            buf2 <= {WIDTH{1'b0}};
        end
        else begin
            buf1 <= din;
            buf2 <= buf1;
        end
    end
    
    // 匹配计算逻辑
    always @(posedge clk or posedge async_rst) begin
        if (async_rst) begin
            match_din_buf1 <= {WIDTH{1'b0}};
            match_din_buf2 <= {WIDTH{1'b0}};
            match_buf1_buf2 <= {WIDTH{1'b0}};
        end
        else begin
            match_din_buf1 <= din & buf1;
            match_din_buf2 <= din & buf2;
            match_buf1_buf2 <= buf1 & buf2;
        end
    end
    
    // 数据恢复逻辑
    always @(posedge clk or posedge async_rst) begin
        if (async_rst) begin
            recovery_data <= {WIDTH{1'b0}};
        end
        else begin
            recovery_data <= match_buf1_buf2 | match_din_buf1 | match_din_buf2;
        end
    end
    
    // 输出逻辑
    always @(posedge clk or posedge async_rst) begin
        if (async_rst) begin
            dout <= {WIDTH{1'b0}};
        end
        else begin
            dout <= recovery_data;
        end
    end
endmodule