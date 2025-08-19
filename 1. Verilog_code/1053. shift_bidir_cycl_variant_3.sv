//SystemVerilog
module shift_bidir_cycl #(parameter WIDTH=8) (
    input  wire                  clk,
    input  wire                  dir,
    input  wire                  en,
    input  wire [WIDTH-1:0]      data_in,
    output reg  [WIDTH-1:0]      data_out
);

// Internal signal to hold the shifted data
reg [WIDTH-1:0] shifted_data;

//-----------------------------------------------------
// Shift Operation: Computes shifted data based on dir
//-----------------------------------------------------
always @(*) begin
    if (dir) begin
        // Right circular shift
        shifted_data = {data_in[0], data_in[WIDTH-1:1]};
    end else begin
        // Left circular shift
        shifted_data = {data_in[WIDTH-2:0], data_in[WIDTH-1]};
    end
end

//-----------------------------------------------------
// Output Register Update: Updates data_out on clk edge
//-----------------------------------------------------
always @(posedge clk) begin
    if (en) begin
        data_out <= shifted_data;
    end
end

endmodule