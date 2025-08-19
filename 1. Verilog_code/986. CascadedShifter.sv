module CascadedShifter #(parameter STAGES=3, WIDTH=8) (
    input clk, en,
    input serial_in,
    output serial_out
);
wire [STAGES:0] stage_wires;
assign stage_wires[0] = serial_in;
genvar i;
generate
    for(i=0; i<STAGES; i=i+1) begin
        ShiftStage #(.WIDTH(WIDTH)) stage(
            .clk(clk),
            .en(en),
            .in(stage_wires[i]),
            .out(stage_wires[i+1])
        );
    end
endgenerate
assign serial_out = stage_wires[STAGES];
endmodule

module ShiftStage #(parameter WIDTH=8) (
    input clk, en, in,
    output reg out
);
reg [WIDTH-1:0] buffer;
always @(posedge clk) begin
    if (en) buffer <= {buffer[WIDTH-2:0], in};
    out <= buffer[WIDTH-1];
end
endmodule