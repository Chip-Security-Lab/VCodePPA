module decoder_dynamic_base (
    input [7:0] base_addr,
    input [7:0] current_addr,
    output reg sel
);
    always @(*) 
        sel = (current_addr[7:4] == base_addr[7:4]) ? 1'b1 : 1'b0;
endmodule