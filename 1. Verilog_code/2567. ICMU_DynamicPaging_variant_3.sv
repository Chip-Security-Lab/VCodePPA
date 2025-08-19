//SystemVerilog
// Page Storage Module
module PageStorage #(
    parameter PAGE_SIZE = 8,
    parameter NUM_PAGES = 4,
    parameter DW = 32
)(
    input clk,
    input [1:0] current_page,
    input [DW-1:0] ctx_in,
    output [DW-1:0] ctx_out
);
    reg [DW-1:0] reg_pages [0:NUM_PAGES-1][0:PAGE_SIZE-1];
    reg [DW-1:0] ctx_out_reg;
    
    always @(posedge clk) begin
        reg_pages[current_page][0] <= ctx_in; // Write to current page
        ctx_out_reg <= reg_pages[current_page][0]; // Pipeline register
    end
    
    assign ctx_out = ctx_out_reg;
endmodule

// Page Control Module
module PageControl #(
    parameter PAGE_SIZE = 8,
    parameter NUM_PAGES = 4,
    parameter DW = 32
)(
    input clk,
    input [1:0] int_level,
    input page_switch,
    output reg [1:0] current_page
);
    reg [1:0] int_level_reg;
    
    always @(posedge clk) begin
        int_level_reg <= int_level; // Pipeline register
        if (page_switch)
            current_page <= int_level_reg;
    end
endmodule

// Top-level ICMU Dynamic Paging Module
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
    wire [1:0] current_page;
    reg [DW-1:0] ctx_in_reg;
    
    // Pipeline register for input
    always @(posedge clk) begin
        ctx_in_reg <= ctx_in;
    end
    
    // Instantiate Page Control submodule
    PageControl #(
        .PAGE_SIZE(PAGE_SIZE),
        .NUM_PAGES(NUM_PAGES),
        .DW(DW)
    ) page_ctrl (
        .clk(clk),
        .int_level(int_level),
        .page_switch(page_switch),
        .current_page(current_page)
    );
    
    // Instantiate Page Storage submodule
    PageStorage #(
        .PAGE_SIZE(PAGE_SIZE),
        .NUM_PAGES(NUM_PAGES),
        .DW(DW)
    ) page_storage (
        .clk(clk),
        .current_page(current_page),
        .ctx_in(ctx_in_reg),
        .ctx_out(ctx_out)
    );
endmodule