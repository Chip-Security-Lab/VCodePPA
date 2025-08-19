module crossbar_sync_prio #(parameter DW=8, N=4) (
    input clk, rst_n, en,
    input [(DW*N)-1:0] din,
    input [(N*2)-1:0] dest,
    output reg [(DW*N)-1:0] dout
);
    // Break out the destination indices
    wire [1:0] dest_indices[0:N-1];
    genvar i;
    generate
        for(i=0; i<N; i=i+1) begin : gen_dest
            assign dest_indices[i] = dest[(i*2+1):(i*2)];
        end
    endgenerate
    
    // Synchronous reset implementation
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            dout <= {(DW*N){1'b0}};
        end else if(en) begin
            dout[DW-1:0] <= din[(dest_indices[0]*DW) +: DW];
            dout[(2*DW)-1:DW] <= din[(dest_indices[1]*DW) +: DW];
            dout[(3*DW)-1:(2*DW)] <= din[(dest_indices[2]*DW) +: DW];
            dout[(4*DW)-1:(3*DW)] <= din[(dest_indices[3]*DW) +: DW];
        end
    end
endmodule