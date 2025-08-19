//SystemVerilog
module CDC_Shifter #(parameter WIDTH=8) (
    input  wire              src_clk,
    input  wire              dst_clk,
    input  wire [WIDTH-1:0]  data_in,
    output wire [WIDTH-1:0]  data_out
);

reg [WIDTH-1:0] data_in_sync;

// Forward retiming: move register after combinational logic
always @(posedge dst_clk) begin
    data_in_sync <= data_in;
end

assign data_out = data_in_sync;

endmodule