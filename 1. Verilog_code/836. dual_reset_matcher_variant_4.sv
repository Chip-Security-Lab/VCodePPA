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
    
    // 实例化数据匹配子模块
    pattern_matcher #(.W(W)) u_pattern_matcher (
        .clk(clk),
        .sync_rst(sync_rst),
        .async_rst_n(async_rst_n),
        .data(data),
        .template(template),
        .match_out(match_r)
    );
    
    // 实例化验证输出子模块
    match_validator u_match_validator (
        .clk(clk),
        .sync_rst(sync_rst),
        .async_rst_n(async_rst_n),
        .match_in(match_r),
        .qualify(qualify),
        .valid_match(valid_match)
    );
    
endmodule

// 数据匹配子模块 - 负责比较数据与模板
module pattern_matcher #(parameter W = 8) (
    input clk, sync_rst, async_rst_n,
    input [W-1:0] data, template,
    output reg match_out
);
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n)
            match_out <= 1'b0;
        else if (sync_rst)
            match_out <= 1'b0;
        else
            match_out <= (data == template);
    end
endmodule

// 验证输出子模块 - 负责根据qualify信号确认匹配是否有效
module match_validator (
    input clk, sync_rst, async_rst_n,
    input match_in, qualify,
    output reg valid_match
);
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n)
            valid_match <= 1'b0;
        else if (sync_rst)
            valid_match <= 1'b0;
        else
            valid_match <= match_in & qualify;
    end
endmodule