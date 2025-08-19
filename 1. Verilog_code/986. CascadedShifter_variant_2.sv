//SystemVerilog
module CascadedShifter #(parameter STAGES=3, WIDTH=8) (
    input  wire               clk,
    input  wire               en,
    input  wire               serial_in,
    output wire               serial_out
);

// Internal stage wires (unbuffered)
wire [STAGES:0] stage_wires_unbuf;

// First-level buffer registers for stage wires
reg  [STAGES:0] stage_wires_buf_lvl1;

// Second-level buffer registers for stage wires (for increased fanout buffering)
reg  [STAGES:0] stage_wires_buf_lvl2;

// Assign initial value to the unbuffered stage wires
assign stage_wires_unbuf[0] = serial_in;

// First-level buffering for high fanout stage_wires
always @(posedge clk) begin
    if (en) begin
        stage_wires_buf_lvl1[0] <= stage_wires_unbuf[0];
        stage_wires_buf_lvl1[1] <= stage_wires_unbuf[1];
        stage_wires_buf_lvl1[2] <= stage_wires_unbuf[2];
        stage_wires_buf_lvl1[3] <= stage_wires_unbuf[3];
    end
end

// Second-level buffering for high fanout stage_wires
always @(posedge clk) begin
    if (en) begin
        stage_wires_buf_lvl2[0] <= stage_wires_buf_lvl1[0];
        stage_wires_buf_lvl2[1] <= stage_wires_buf_lvl1[1];
        stage_wires_buf_lvl2[2] <= stage_wires_buf_lvl1[2];
        stage_wires_buf_lvl2[3] <= stage_wires_buf_lvl1[3];
    end
end

genvar i;
generate
    for(i=0; i<STAGES; i=i+1) begin : SHIFT_STAGE_GEN
        ShiftStage #(.WIDTH(WIDTH)) stage_inst (
            .clk(clk),
            .en(en),
            .in(stage_wires_buf_lvl2[i]),
            .out(stage_wires_unbuf[i+1])
        );
    end
endgenerate

// Output buffer chain for serial_out
reg serial_out_buf1, serial_out_buf2;
always @(posedge clk) begin
    if (en) begin
        serial_out_buf1 <= stage_wires_buf_lvl2[STAGES];
        serial_out_buf2 <= serial_out_buf1;
    end
end

assign serial_out = serial_out_buf2;

endmodule

module ShiftStage #(parameter WIDTH=8) (
    input  wire clk,
    input  wire en,
    input  wire in,
    output reg  out
);
    reg [WIDTH-1:0] shift_buffer;
    always @(posedge clk) begin
        if (en)
            shift_buffer <= {shift_buffer[WIDTH-2:0], in};
        out <= shift_buffer[WIDTH-1];
    end
endmodule