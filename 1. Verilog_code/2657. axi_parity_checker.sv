module axi_parity_checker (
    input aclk, arstn,
    input [31:0] tdata,
    input tvalid,
    output reg tparity
);
always @(posedge aclk or negedge arstn) begin
    if (!arstn) tparity <= 0;
    else if (tvalid) tparity <= ^tdata;
end
endmodule