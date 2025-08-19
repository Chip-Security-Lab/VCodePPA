//SystemVerilog
module counter_clock_gate (
    input  wire clk_in,
    input  wire rst_n,
    input  wire [3:0] div_ratio,
    output wire clk_out
);
    // 阶段1: 计数和比较逻辑
    reg [3:0] cnt_stage1;
    reg comp_result_stage1;
    
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            cnt_stage1 <= 4'b0;
            comp_result_stage1 <= 1'b1; // 复位时输出高电平
        end
        else begin
            cnt_stage1 <= (cnt_stage1 == div_ratio) ? 4'b0 : cnt_stage1 + 1'b1;
            comp_result_stage1 <= (cnt_stage1 == div_ratio) ? 1'b1 : (cnt_stage1 == 4'b0);
        end
    end
    
    // 阶段2: 输出逻辑
    reg comp_result_stage2;
    
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n)
            comp_result_stage2 <= 1'b1; // 复位时输出高电平
        else
            comp_result_stage2 <= comp_result_stage1;
    end
    
    // 输出时钟
    assign clk_out = clk_in & comp_result_stage2;
endmodule