//SystemVerilog
// 顶层模块
module dual_reset_matcher #(parameter W = 8) (
    input clk, sync_rst, async_rst_n,
    input [W-1:0] data, template,
    input qualify,
    output valid_match
);
    // 内部连线
    wire match_r;
    
    // 子模块实例化
    match_detector #(
        .W(W)
    ) u_match_detector (
        .clk(clk),
        .sync_rst(sync_rst),
        .async_rst_n(async_rst_n),
        .data(data),
        .template(template),
        .match_result(match_r)
    );
    
    match_qualifier u_match_qualifier (
        .clk(clk),
        .sync_rst(sync_rst),
        .async_rst_n(async_rst_n),
        .match_r(match_r),
        .qualify(qualify),
        .valid_match(valid_match)
    );
    
endmodule

// 子模块1：匹配检测器
module match_detector #(parameter W = 8) (
    input clk, sync_rst, async_rst_n,
    input [W-1:0] data, template,
    output reg match_result
);
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n)
            match_result <= 1'b0;
        else if (sync_rst)
            match_result <= 1'b0;
        else
            match_result <= (data == template);
    end
endmodule

// 子模块2：匹配资格验证器
module match_qualifier (
    input clk, sync_rst, async_rst_n,
    input match_r, qualify,
    output reg valid_match
);
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n)
            valid_match <= 1'b0;
        else if (sync_rst)
            valid_match <= 1'b0;
        else
            valid_match <= match_r & qualify;
    end
endmodule