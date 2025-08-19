module touch_decoder (
    input [11:0] x_raw, y_raw,
    output reg [10:0] x_pos, y_pos
);
always @(*) begin
    x_pos = x_raw[11:1] + 5;  // Add calibration offset
    y_pos = y_raw[11:1] >> 1; // Scale down
end
endmodule
