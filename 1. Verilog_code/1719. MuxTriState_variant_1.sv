//SystemVerilog
module MuxTriState #(parameter W=8, N=4) (
    inout [W-1:0] bus,
    input [W-1:0] data_in [0:N-1],
    input [N-1:0] oe
);

    reg [W-1:0] bus_reg;
    wire [W-1:0] bus_out;
    
    always @(*) begin
        bus_reg = {W{1'bz}};
        for (integer i = 0; i < N; i = i + 1) begin
            if (oe[i]) begin
                bus_reg = data_in[i];
            end
        end
    end
    
    assign bus = bus_out;
    assign bus_out = bus_reg;

endmodule