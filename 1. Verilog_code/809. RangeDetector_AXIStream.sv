module RangeDetector_AXIStream #(
    parameter WIDTH = 8
)(
    input clk, rst_n,
    input tvalid,
    input [WIDTH-1:0] tdata,
    input [WIDTH-1:0] lower,
    input [WIDTH-1:0] upper,
    output reg tvalid_out,
    output reg [WIDTH-1:0] tdata_out
);
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        tvalid_out <= 0;
        tdata_out <= 0;
    end
    else begin
        tvalid_out <= tvalid;
        tdata_out <= (tdata >= lower && tdata <= upper) ? tdata : 0;
    end
end
endmodule