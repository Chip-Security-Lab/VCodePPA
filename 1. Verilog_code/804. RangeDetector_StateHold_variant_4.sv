//SystemVerilog
//========================================================================
// 顶层模块：RangeDetector_StateHold
//========================================================================
module RangeDetector_StateHold #(
    parameter WIDTH = 8
)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] threshold,
    output state_flag
);
    // 内部连线
    wire comparison_result;
    
    // 实例化子模块
    DataComparator #(
        .WIDTH(WIDTH)
    ) u_data_comparator (
        .data_in(data_in),
        .threshold(threshold),
        .greater_than(comparison_result)
    );
    
    StateController u_state_controller (
        .clk(clk),
        .rst_n(rst_n),
        .comparison_result(comparison_result),
        .state_flag(state_flag)
    );
    
endmodule

//========================================================================
// 子模块1：数据比较器
//========================================================================
module DataComparator #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] threshold,
    output greater_than
);
    // 组合逻辑比较
    assign greater_than = (data_in > threshold);
    
endmodule

//========================================================================
// 子模块2：状态控制器
//========================================================================
module StateController (
    input clk,
    input rst_n,
    input comparison_result,
    output reg state_flag
);
    // 状态保持逻辑
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state_flag <= 1'b0;
        end
        else begin
            if(comparison_result) begin
                state_flag <= 1'b1;
            end
            else begin
                state_flag <= 1'b0;
            end
        end
    end
    
endmodule