module RangeDetector_CDC #(
    parameter WIDTH = 8
)(
    input src_clk,
    input dst_clk,
    input rst_n,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] threshold,
    output reg flag_out
);
reg [WIDTH-1:0] src_data;
reg src_flag, meta_flag, dst_flag;

// 源时钟域
always @(posedge src_clk) begin
    src_data <= data_in;
    src_flag <= (data_in > threshold);
end

// 同步器链
always @(posedge dst_clk or negedge rst_n) begin
    if(!rst_n) begin
        meta_flag <= 0;
        dst_flag <= 0;
    end
    else begin
        meta_flag <= src_flag;
        dst_flag <= meta_flag;
    end
end

always @(posedge dst_clk) begin
    flag_out <= dst_flag;
end
endmodule