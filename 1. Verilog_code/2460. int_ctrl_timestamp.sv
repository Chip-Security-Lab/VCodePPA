module int_ctrl_timestamp #(TS_W=16)(
    input clk, int_pulse,
    output reg [TS_W-1:0] timestamp
);
reg [TS_W-1:0] counter;
always @(posedge clk) begin
    counter <= counter + 1;
    if(int_pulse) timestamp <= counter;
end
endmodule