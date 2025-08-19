module preload_shift_reg (
    input clk, load,
    input [3:0] shift,
    input [15:0] load_data,
    output reg [15:0] shifted
);
reg [15:0] storage;
always @(posedge clk) begin
    if (load) storage <= load_data;
    else shifted <= (storage << shift) | (storage >> (16 - shift));
end
endmodule