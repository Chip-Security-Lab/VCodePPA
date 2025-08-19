//SystemVerilog
// Page Memory Module
module PageMemory #(
    parameter PAGE_SIZE = 8,
    parameter NUM_PAGES = 4,
    parameter DW = 32
)(
    input clk,
    input [1:0] page_addr,
    input [DW-1:0] write_data,
    input write_en,
    output [DW-1:0] read_data
);
    reg [DW-1:0] reg_pages [0:NUM_PAGES-1][0:PAGE_SIZE-1];
    wire [DW-1:0] read_data_next;
    
    // Optimized write logic with registered output
    always @(posedge clk) begin
        if (write_en) begin
            reg_pages[page_addr][0] <= write_data;
        end
    end
    
    // Registered read path for better timing
    reg [DW-1:0] read_data_reg;
    always @(posedge clk) begin
        read_data_reg <= reg_pages[page_addr][0];
    end
    
    assign read_data = read_data_reg;
endmodule

// Page Controller Module
module PageController #(
    parameter NUM_PAGES = 4
)(
    input clk,
    input [1:0] int_level,
    input page_switch,
    output reg [1:0] current_page
);
    // Optimized page switching logic
    wire [1:0] next_page = page_switch ? int_level : current_page;
    
    always @(posedge clk) begin
        current_page <= next_page;
    end
endmodule

// Top Level Module
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
    
    PageController #(
        .NUM_PAGES(NUM_PAGES)
    ) page_ctrl (
        .clk(clk),
        .int_level(int_level),
        .page_switch(page_switch),
        .current_page(current_page)
    );
    
    PageMemory #(
        .PAGE_SIZE(PAGE_SIZE),
        .NUM_PAGES(NUM_PAGES),
        .DW(DW)
    ) page_mem (
        .clk(clk),
        .page_addr(current_page),
        .write_data(ctx_in),
        .write_en(1'b1),
        .read_data(ctx_out)
    );
endmodule