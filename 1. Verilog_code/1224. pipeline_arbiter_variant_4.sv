//SystemVerilog
module pipeline_arbiter #(parameter WIDTH=4) (
    input clk, rst_n,
    input [WIDTH-1:0] req_i,
    output reg [WIDTH-1:0] grant_o
);

    // Internal signals
    reg [WIDTH-1:0] req_i_buf;
    wire [WIDTH-1:0] priority_mask;
    reg [WIDTH-1:0] priority_mask_reg;
    wire [WIDTH-1:0] stage1_wire;
    reg [WIDTH-1:0] stage1, stage2;
    
    // 计算优先级掩码的组合逻辑
    assign priority_mask = ~req_i + 1'b1;
    
    // 计算stage1的组合逻辑
    assign stage1_wire = req_i & priority_mask;
    
    // 前向寄存器重定时：将输入寄存器移动到组合逻辑之后
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            req_i_buf <= {WIDTH{1'b0}};
            priority_mask_reg <= {WIDTH{1'b0}};
            stage1 <= {WIDTH{1'b0}};
        end else begin
            req_i_buf <= req_i;
            priority_mask_reg <= priority_mask;
            stage1 <= stage1_wire;
        end
    end
    
    // Stage 2 和输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2 <= {WIDTH{1'b0}};
            grant_o <= {WIDTH{1'b0}};
        end else begin
            stage2 <= stage1;
            grant_o <= stage2;
        end
    end
    
endmodule