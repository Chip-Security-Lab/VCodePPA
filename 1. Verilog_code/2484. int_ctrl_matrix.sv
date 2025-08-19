module int_ctrl_matrix #(
    parameter N = 4
)(
    input clk,
    input [N-1:0] req,
    input [N*N-1:0] prio_table,
    output reg [N-1:0] grant
);
    integer i, j;
    reg [N-1:0] temp_grant;
    reg [N-1:0] conflicts;
    
    always @(posedge clk) begin
        grant <= {N{1'b0}};
        temp_grant = {N{1'b0}};
        
        for(i = 0; i < N; i = i + 1) begin
            if(req[i]) begin
                conflicts = {N{1'b0}};
                for(j = 0; j < N; j = j + 1)
                    if(prio_table[i*N+j]) conflicts[j] = temp_grant[j];
                
                if(!(|conflicts))
                    temp_grant[i] = 1'b1;
            end
        end
        
        grant <= temp_grant;
    end
endmodule