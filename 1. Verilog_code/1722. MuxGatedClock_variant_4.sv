//SystemVerilog
module MuxGatedClock #(parameter W=4) (
    input gclk, en,
    input [3:0][W-1:0] din,
    input [1:0] sel,
    output reg [W-1:0] q
);

reg [W-1:0] selected_data;
reg valid;

always @(*) begin
    selected_data = din[sel];
    valid = en;
end

always @(posedge gclk) begin
    if (valid) begin
        q <= selected_data;
    end
end

endmodule