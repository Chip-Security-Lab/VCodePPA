module int_ctrl_dyn_prio #(parameter N=4)(
    input clk,
    input [N-1:0] int_req,
    input [N-1:0] prio_reg,
    output reg [N-1:0] grant
);
    integer i;
    
    always @(*) begin
        grant = 0;
        for(i = 0; i < N; i = i + 1)
            if(int_req[i] & prio_reg[i])
                grant[i] = 1;
    end
endmodule