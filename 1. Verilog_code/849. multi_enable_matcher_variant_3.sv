//SystemVerilog
module multi_enable_matcher #(parameter DW = 8) (
    input clk, rst_n,
    input [DW-1:0] data, pattern,
    input en_capture, en_compare,
    output reg match
);
    reg [DW-1:0] stored_data;
    reg [DW-1:0] registered_pattern;
    reg en_compare_r;
    wire [DW-1:0] inverted_pattern;
    wire [DW:0] subtraction_result;
    wire is_zero;
    
    // 注册pattern输入和控制信号以减少关键路径
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            registered_pattern <= {DW{1'b0}};
            en_compare_r <= 1'b0;
        end else begin
            registered_pattern <= pattern;
            en_compare_r <= en_compare;
        end
    end
    
    // 补码加法实现减法: A-B = A+(-B) = A+(~B+1)
    assign inverted_pattern = ~registered_pattern;
    assign subtraction_result = {1'b0, stored_data} + {1'b0, inverted_pattern} + {{DW{1'b0}}, 1'b1};
    assign is_zero = (subtraction_result[DW-1:0] == {DW{1'b0}});
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stored_data <= {DW{1'b0}};
            match <= 1'b0;
        end else begin
            if (en_capture)
                stored_data <= data;
            if (en_compare_r)
                match <= is_zero;
        end
    end
endmodule