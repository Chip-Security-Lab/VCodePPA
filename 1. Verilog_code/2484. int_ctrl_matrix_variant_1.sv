//SystemVerilog
//IEEE 1364-2005 Verilog
module int_ctrl_matrix #(
    parameter N = 4
)(
    input clk,
    input [N-1:0] req,
    input [N*N-1:0] prio_table,
    output reg [N-1:0] grant
);
    reg [N-1:0] temp_grant;
    reg [N-1:0] conflicts;
    reg has_conflict;
    
    integer i, j;
    
    always @(posedge clk) begin
        temp_grant = {N{1'b0}};
        
        for (i = 0; i < N; i = i + 1) begin
            if (req[i]) begin
                has_conflict = 1'b0;
                
                // 快速冲突检测 - 使用位操作而不是循环比较每个位
                conflicts = temp_grant & prio_table[i*N +: N];
                
                if (conflicts == {N{1'b0}}) begin
                    temp_grant[i] = 1'b1;
                end
            end
        end
        
        grant <= temp_grant;
    end
endmodule