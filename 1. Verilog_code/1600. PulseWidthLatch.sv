module PulseWidthLatch (
    input clk, pulse,
    output reg [15:0] width_count
);
reg last_pulse;
always @(posedge clk) begin
    last_pulse <= pulse;
    if(pulse && !last_pulse) width_count <= 0;
    else if(pulse) width_count <= width_count + 1;
end
endmodule