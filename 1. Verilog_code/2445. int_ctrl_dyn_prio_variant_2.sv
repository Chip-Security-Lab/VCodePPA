//SystemVerilog
module int_ctrl_dyn_prio #(parameter N=4)(
    input clk,
    input [N-1:0] int_req,
    input [N-1:0] prio_reg,
    output reg [N-1:0] grant
);
    // Internal signals for borrow subtractor implementation
    reg [N-1:0] result;
    reg [N:0] borrow;
    integer i;
    
    always @(*) begin
        // Initialize borrow
        borrow[0] = 1'b0;
        
        // Implement borrow subtractor algorithm for 8-bit operation
        for (i = 0; i < 8; i = i + 1) begin
            if (i < N) begin
                result[i] = int_req[i] ^ prio_reg[i] ^ borrow[i];
                borrow[i+1] = (~int_req[i] & prio_reg[i]) | (~int_req[i] & borrow[i]) | (prio_reg[i] & borrow[i]);
            end
        end
        
        // Apply dynamic priority logic with the borrow subtractor result
        grant = int_req & (result | prio_reg);
    end
endmodule