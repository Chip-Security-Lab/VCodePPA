//SystemVerilog
module ICMU_DynamicPaging #(
    parameter PAGE_SIZE = 8,
    parameter NUM_PAGES = 4,
    parameter DW = 32
)(
    input clk,
    input [1:0] int_level,
    input page_switch,
    input [DW-1:0] ctx_in,
    output [DW-1:0] ctx_out
);
    reg [DW-1:0] reg_pages [0:NUM_PAGES-1][0:PAGE_SIZE-1];
    reg [1:0] current_page;
    reg [1:0] next_page;
    
    // 补码加法实现减法
    wire [2:0] page_diff_sum;
    wire [1:0] page_diff_final;
    
    assign page_diff_sum = {1'b0, int_level} + {1'b0, ~current_page} + 1'b1;
    assign page_diff_final = page_diff_sum[1:0];
    
    always @(posedge clk) begin
        if (page_switch) begin
            current_page <= next_page;
            next_page <= int_level;
        end
    end
    
    always @(posedge clk) begin
        reg_pages[current_page][0] <= ctx_in;
    end
    
    assign ctx_out = reg_pages[current_page][0];
endmodule