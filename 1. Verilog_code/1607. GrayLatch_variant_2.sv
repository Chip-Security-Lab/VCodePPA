//SystemVerilog
module GrayLatch #(parameter DW=4) (
    input clk, en,
    input [DW-1:0] bin_in,
    output reg [DW-1:0] gray_out
);

reg [DW-1:0] bin_reg;
reg [DW-1:0] shifted_bin;
reg [DW-1:0] gray_temp;

// Input register stage
always @(posedge clk) begin
    if(en) begin
        bin_reg <= bin_in;
    end
end

// Shift operation stage
always @(posedge clk) begin
    if(en) begin
        shifted_bin <= bin_in >> 1;
    end
end

// Gray code conversion stage
always @(posedge clk) begin
    if(en) begin
        gray_temp <= bin_reg ^ shifted_bin;
    end
end

// Output stage
always @(posedge clk) begin
    if(en) begin
        gray_out <= gray_temp;
    end
end

endmodule