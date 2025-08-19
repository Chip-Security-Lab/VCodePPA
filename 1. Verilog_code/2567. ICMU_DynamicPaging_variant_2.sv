//SystemVerilog
module ICMU_DynamicPaging #(
    parameter PAGE_SIZE = 8,
    parameter NUM_PAGES = 4,
    parameter DW = 32
)(
    input clk,
    input rst_n,
    input [1:0] int_level,
    input page_switch,
    input [DW-1:0] ctx_in,
    output [DW-1:0] ctx_out
);

    // Pipeline stage 1: Page selection and input registration
    reg [1:0] current_page_stage1;
    reg [1:0] next_page_stage1;
    reg [DW-1:0] ctx_in_stage1;
    reg valid_stage1;

    // Pipeline stage 2: Memory access
    reg [1:0] current_page_stage2;
    reg [DW-1:0] ctx_in_stage2;
    reg valid_stage2;
    reg [DW-1:0] reg_pages [0:NUM_PAGES-1][0:PAGE_SIZE-1];

    // Pipeline stage 3: Output selection
    reg [1:0] current_page_stage3;
    reg [DW-1:0] ctx_out_stage3;
    reg valid_stage3;

    // Stage 1 logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_page_stage1 <= 2'b0;
            next_page_stage1 <= 2'b0;
            ctx_in_stage1 <= {DW{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            next_page_stage1 <= page_switch ? int_level : current_page_stage1;
            current_page_stage1 <= next_page_stage1;
            ctx_in_stage1 <= ctx_in;
            valid_stage1 <= 1'b1;
        end
    end

    // Stage 2 logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_page_stage2 <= 2'b0;
            ctx_in_stage2 <= {DW{1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            current_page_stage2 <= current_page_stage1;
            ctx_in_stage2 <= ctx_in_stage1;
            valid_stage2 <= valid_stage1;
            if (valid_stage1) begin
                reg_pages[next_page_stage1][0] <= ctx_in_stage1;
            end
        end
    end

    // Stage 3 logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_page_stage3 <= 2'b0;
            ctx_out_stage3 <= {DW{1'b0}};
            valid_stage3 <= 1'b0;
        end else begin
            current_page_stage3 <= current_page_stage2;
            ctx_out_stage3 <= reg_pages[current_page_stage2][0];
            valid_stage3 <= valid_stage2;
        end
    end

    assign ctx_out = valid_stage3 ? ctx_out_stage3 : {DW{1'b0}};

endmodule