//SystemVerilog
module ms_jk_flip_flop (
    input wire clk,
    input wire j,
    input wire k,
    output wire q
);
    reg master, slave;
    wire next_master;
    
    // Pre-compute next master value to reduce critical path
    assign next_master = ({j,k} == 2'b00) ? master :
                         ({j,k} == 2'b01) ? 1'b0 :
                         ({j,k} == 2'b10) ? 1'b1 : ~master;
    
    // Split the original always block into two separate blocks for better timing
    always @(posedge clk) begin
        master <= next_master;
    end
    
    always @(negedge clk) begin
        slave <= master;
    end
    
    assign q = slave;
endmodule