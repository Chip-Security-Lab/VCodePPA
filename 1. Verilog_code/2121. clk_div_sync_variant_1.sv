//SystemVerilog
module clk_div_sync #(
    parameter DIV = 4
)(
    input clk_in,
    input rst_n,
    input en,
    output reg clk_out
);
    // Optimize counter width based on DIV parameter
    reg [$clog2(DIV):0] counter_stage1;
    reg [$clog2(DIV):0] counter_stage2;
    
    // Pre-compute the comparison value
    localparam HALF_DIV_MINUS_1 = (DIV/2) - 1;
    
    // Pipeline control signals
    reg en_stage1;
    reg en_stage2;
    
    // Pipeline data signals
    reg clk_out_stage1;
    
    // Pipeline stage 1: Counter increment logic
    wire counter_at_max_stage1 = (counter_stage1 == HALF_DIV_MINUS_1);
    wire [$clog2(DIV):0] next_counter = counter_at_max_stage1 ? {($clog2(DIV)+1){1'b0}} : counter_stage1 + 1'b1;
    
    // Pipeline stage 2: Clock toggle logic
    wire counter_at_max_stage2 = (counter_stage2 == HALF_DIV_MINUS_1);
    wire next_clk_out = counter_at_max_stage2 ? ~clk_out_stage1 : clk_out_stage1;
    
    // Stage 1 pipeline registers
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            counter_stage1 <= {($clog2(DIV)+1){1'b0}};
            en_stage1 <= 1'b0;
        end else begin
            en_stage1 <= en;
            if (en) begin
                counter_stage1 <= next_counter;
            end
        end
    end
    
    // Stage 2 pipeline registers
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            counter_stage2 <= {($clog2(DIV)+1){1'b0}};
            clk_out_stage1 <= 1'b0;
            en_stage2 <= 1'b0;
        end else begin
            counter_stage2 <= counter_stage1;
            clk_out_stage1 <= clk_out;
            en_stage2 <= en_stage1;
        end
    end
    
    // Output stage
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            clk_out <= 1'b0;
        end else if (en_stage2) begin
            clk_out <= next_clk_out;
        end
    end
endmodule