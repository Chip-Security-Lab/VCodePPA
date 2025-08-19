//SystemVerilog
module async_div #(
    parameter DIV = 4
) (
    input  wire clk_in,
    input  wire rst_n,
    output wire clk_out
);

    // Parameter validation and calculations
    localparam MAX_DIV = 16;
    localparam COUNTER_WIDTH = $clog2(MAX_DIV);
    
    // Pipeline stage 1: Counter handling
    reg [COUNTER_WIDTH-1:0] counter_stage1;
    reg [COUNTER_WIDTH-1:0] counter_next;
    reg counter_overflow;
    reg counter_halfpoint;
    
    // Pipeline stage 2: Clock generation control signals
    reg toggle_clk_stage2;
    
    // Pipeline stage 3: Output generation
    reg clk_out_reg_stage3;
    
    // Stage 1: Calculate next counter value and control signals
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            counter_stage1 <= {COUNTER_WIDTH{1'b0}};
            counter_next <= {COUNTER_WIDTH{1'b0}};
            counter_overflow <= 1'b0;
            counter_halfpoint <= 1'b0;
        end else begin
            // Calculate next counter value
            counter_next <= (counter_stage1 == DIV-1) ? {COUNTER_WIDTH{1'b0}} : counter_stage1 + 1'b1;
            counter_stage1 <= counter_next;
            
            // Generate control signals
            counter_overflow <= (counter_stage1 == DIV-1);
            counter_halfpoint <= (counter_stage1 == DIV/2-1);
        end
    end
    
    // Stage 2: Determine when to toggle clock
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            toggle_clk_stage2 <= 1'b0;
        end else begin
            toggle_clk_stage2 <= counter_overflow || counter_halfpoint;
        end
    end
    
    // Stage 3: Generate output clock
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            clk_out_reg_stage3 <= 1'b0;
        end else begin
            if (toggle_clk_stage2)
                clk_out_reg_stage3 <= ~clk_out_reg_stage3;
        end
    end
    
    // Output assignment
    assign clk_out = clk_out_reg_stage3;

endmodule