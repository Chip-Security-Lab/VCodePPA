//SystemVerilog
module int_ctrl_dynamic #(
    parameter N_SRC = 8
)(
    input clk, rst,
    input [N_SRC-1:0] req,
    input [N_SRC*8-1:0] prio_map,
    output reg [2:0] curr_pri
);
    integer i, j;
    reg [2:0] temp_pri;
    
    always @(posedge clk) begin
        if(rst) curr_pri <= 3'b0;
        else begin
            temp_pri = 3'b0;
            
            i = 7;
            while(i >= 0) begin
                j = 0;
                while(j < N_SRC) begin
                    if(req[j] & prio_map[i*N_SRC+j]) begin
                        temp_pri = i[2:0];
                    end
                    j = j + 1;
                end
                i = i - 1;
            end
            
            curr_pri <= temp_pri;
        end
    end
endmodule