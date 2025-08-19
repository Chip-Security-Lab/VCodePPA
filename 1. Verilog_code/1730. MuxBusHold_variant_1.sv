//SystemVerilog
module MuxBusHold #(parameter W=4) (
    input [3:0][W-1:0] bus_in,
    input [1:0] sel,
    input hold,
    output reg [W-1:0] bus_out
);
    wire [W-1:0] mux_out;
    wire [W-1:0] hold_mask;
    wire [W-1:0] new_data;
    wire [W-1:0] inverted_hold_mask;
    
    assign mux_out = bus_in[sel];
    assign hold_mask = {W{hold}};
    assign inverted_hold_mask = ~hold_mask;
    assign new_data = (mux_out & inverted_hold_mask) | (bus_out & hold_mask);
    
    always @(*) begin
        bus_out = new_data;
    end
endmodule