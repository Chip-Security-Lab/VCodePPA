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
    
    always @(posedge clk) begin
        if (page_switch)
            current_page <= int_level;
    end
    
    always @(posedge clk) begin
        reg_pages[current_page][0] <= ctx_in; // 示例写入位置
    end
    
    assign ctx_out = reg_pages[current_page][0];
endmodule
