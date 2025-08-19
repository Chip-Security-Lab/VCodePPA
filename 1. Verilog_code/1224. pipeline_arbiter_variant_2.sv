//SystemVerilog
module pipeline_arbiter #(WIDTH=8) (
    input clk, rst_n,
    input [WIDTH-1:0] req_i,
    output reg [WIDTH-1:0] grant_o
);
    reg [WIDTH-1:0] stage1, stage2;
    wire [WIDTH-1:0] priority_select;
    
    // 简化的优先级选择逻辑
    // 使用req_i & (~req_i + 1)提取最低位的1
    // 这是一个常见的位操作技巧，可以高效地找到最低有效位
    assign priority_select = req_i & (~req_i + 1'b1);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1 <= {WIDTH{1'b0}};
            stage2 <= {WIDTH{1'b0}};
            grant_o <= {WIDTH{1'b0}};
        end else begin
            stage1 <= priority_select;    // Stage1: priority select
            stage2 <= stage1;             // Stage2: pipeline register
            grant_o <= stage2;            // Stage3: output
        end
    end
endmodule