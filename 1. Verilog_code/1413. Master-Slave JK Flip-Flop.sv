module ms_jk_flip_flop (
    input wire clk,
    input wire j,
    input wire k,
    output wire q
);
    reg master, slave;
    
    always @(posedge clk) begin
        case ({j, k})
            2'b00: master <= master;
            2'b01: master <= 1'b0;
            2'b10: master <= 1'b1;
            2'b11: master <= ~master;
        endcase
    end
    
    always @(negedge clk) begin
        slave <= master;
    end
    
    assign q = slave;
endmodule