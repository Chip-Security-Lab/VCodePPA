//SystemVerilog
module MuxTriState #(parameter W=8, N=4) (
    inout [W-1:0] bus,
    input [W-1:0] data_in [0:N-1],
    input [N-1:0] oe
);
    // Optimized tri-state buffer implementation
    wire [W-1:0] bus_drive [0:N-1];
    
    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin: gen_mux
            assign bus_drive[i] = oe[i] ? data_in[i] : {W{1'bz}};
        end
    endgenerate
    
    // Parallel tri-state buffer connection
    assign bus = bus_drive[0] & bus_drive[1] & bus_drive[2] & bus_drive[3];
endmodule