module CascadeShift #(parameter STAGES=3, WIDTH=8) (
    input clk, cascade_en,
    input [WIDTH-1:0] din,
    output [WIDTH-1:0] dout
);
reg [WIDTH-1:0] stage [0:STAGES-1];
integer i;

always @(posedge clk) begin
    if (cascade_en) begin
        stage[0] <= din;
        for(i=1; i<STAGES; i=i+1)
            stage[i] <= stage[i-1];
    end
end
assign dout = stage[STAGES-1];
endmodule