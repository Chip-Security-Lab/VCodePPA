//SystemVerilog
module pipeline_arbiter #(
    parameter WIDTH = 4
) (
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] req_i,
    output reg [WIDTH-1:0] grant_o
);
    // 将输入寄存并重新排列管道阶段
    reg [WIDTH-1:0] req_reg;
    reg [WIDTH-1:0] req_inverted;
    reg [WIDTH-1:0] incremented_inv_req;
    reg [WIDTH-1:0] priority_mask;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            req_reg <= {WIDTH{1'b0}};
            req_inverted <= {WIDTH{1'b0}};
            incremented_inv_req <= {WIDTH{1'b0}};
            priority_mask <= {WIDTH{1'b0}};
            grant_o <= {WIDTH{1'b0}};
        end else begin
            // 第一级：寄存输入并进行反转操作
            req_reg <= req_i;
            req_inverted <= ~req_reg;
            
            // 第二级：处理增量操作
            incremented_inv_req <= req_inverted + 1'b1;
            
            // 第三级：计算优先级掩码
            priority_mask <= req_reg & incremented_inv_req;
            
            // 第四级：输出结果
            grant_o <= priority_mask;
        end
    end
endmodule