module decoder_crossbar #(MASTERS=2, SLAVES=4) (
    input [MASTERS-1:0] master_req,
    input [MASTERS-1:0][7:0] addr,
    output reg [MASTERS-1:0][SLAVES-1:0] slave_sel
);
genvar i;
generate
    for(i=0; i<MASTERS; i=i+1) begin
        always @* begin
            slave_sel[i] = master_req[i] ? 
                (1 << (addr[i] % SLAVES)) : {SLAVES{1'b0}};
        end
    end
endgenerate
endmodule