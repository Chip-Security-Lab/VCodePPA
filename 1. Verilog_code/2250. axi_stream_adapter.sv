module axi_stream_adapter #(parameter DW=32) (
    input clk, resetn,
    input [DW-1:0] tdata,
    input tvalid,
    output reg tready,
    output reg [DW-1:0] rdata,
    output reg rvalid
);
    always @(posedge clk) begin
        if(!resetn) begin
            tready <= 1'b1;
            rvalid <= 1'b0;
            rdata <= {DW{1'b0}}; // 初始化rdata
        end else if(tvalid & tready) begin
            rdata <= tdata; // 将输入数据传递到输出
            rvalid <= 1'b1;
            tready <= 1'b0;
        end else begin
            rvalid <= 1'b0;
            tready <= 1'b1;
        end
    end
endmodule