//SystemVerilog
module cdc_arbiter #(WIDTH=4) (
    input clk_a, clk_b, rst_n,
    input [WIDTH-1:0] req_a,
    output [WIDTH-1:0] grant_b
);
    // 声明所有内部信号
    reg [WIDTH-1:0] req_a_reg;
    reg [WIDTH-1:0] sync0, sync1;
    reg [WIDTH-1:0] grant_b_reg;
    wire [WIDTH-1:0] priority_grant;
    
    // 输入寄存 - 时钟域A
    always @(posedge clk_a or negedge rst_n) begin
        if (!rst_n) 
            req_a_reg <= {WIDTH{1'b0}};
        else
            req_a_reg <= req_a;
    end
    
    // CDC同步第一级 - 时钟域B
    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n)
            sync0 <= {WIDTH{1'b0}};
        else
            sync0 <= req_a_reg;
    end
    
    // CDC同步第二级 - 时钟域B
    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n)
            sync1 <= {WIDTH{1'b0}};
        else
            sync1 <= sync0;
    end
    
    // 仲裁逻辑 - 组合逻辑
    assign priority_grant = sync1 & (~sync1 + 1'b1);
    
    // 输出寄存 - 时钟域B
    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n)
            grant_b_reg <= {WIDTH{1'b0}};
        else
            grant_b_reg <= priority_grant;
    end
    
    // 输出驱动
    assign grant_b = grant_b_reg;
    
endmodule