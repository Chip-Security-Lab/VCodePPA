//SystemVerilog
// Counter submodule
module TimeSliceCounter #(parameter SLICE_WIDTH=8) (
    input clk,
    input rst,
    output reg [SLICE_WIDTH-1:0] count
);

always @(posedge clk) begin
    if (rst || count == 4) begin
        count <= 0;
    end else begin
        count <= count + 1;
    end
end

endmodule

// Grant generator submodule
module GrantGenerator (
    input [3:0] req,
    input [1:0] slice_idx,
    output reg [3:0] grant
);

always @(*) begin
    grant = req & (1 << slice_idx);
end

endmodule

// Top-level module
module TimeSliceArbiter #(parameter SLICE_WIDTH=8) (
    input clk,
    input rst,
    input [3:0] req,
    output [3:0] grant
);

wire [SLICE_WIDTH-1:0] counter;
wire [1:0] slice_idx;

TimeSliceCounter #(.SLICE_WIDTH(SLICE_WIDTH)) counter_inst (
    .clk(clk),
    .rst(rst),
    .count(counter)
);

assign slice_idx = counter[1:0];

GrantGenerator grant_gen_inst (
    .req(req),
    .slice_idx(slice_idx),
    .grant(grant)
);

endmodule