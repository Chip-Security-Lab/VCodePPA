module decoder_partial_match #(parameter MASK=4'hF) (
    input [3:0] addr_in,
    output [7:0] device_sel
);
    assign device_sel = ((addr_in & MASK) == 4'hA) ? 8'h01 : 8'h00;
endmodule