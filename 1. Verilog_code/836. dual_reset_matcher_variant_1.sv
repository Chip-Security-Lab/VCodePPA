//SystemVerilog
module dual_reset_matcher #(parameter W = 8) (
    input clk, sync_rst, async_rst_n,
    input [W-1:0] data, template,
    input qualify,
    output reg valid_match
);
    // Register inputs to improve timing
    reg [W-1:0] data_reg, template_reg;
    reg qualify_reg;
    
    // Register the comparison result
    reg is_match_reg;
    
    // Register input signals to move registers backward through logic
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            data_reg <= {W{1'b0}};
            template_reg <= {W{1'b0}};
            qualify_reg <= 1'b0;
        end
        else if (sync_rst) begin
            data_reg <= {W{1'b0}};
            template_reg <= {W{1'b0}};
            qualify_reg <= 1'b0;
        end
        else begin
            data_reg <= data;
            template_reg <= template;
            qualify_reg <= qualify;
        end
    end
    
    // Compare registered inputs instead of raw inputs
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n)
            is_match_reg <= 1'b0;
        else if (sync_rst)
            is_match_reg <= 1'b0;
        else
            is_match_reg <= (data_reg == template_reg);
    end
    
    // Final output logic
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n)
            valid_match <= 1'b0;
        else if (sync_rst)
            valid_match <= 1'b0;
        else
            valid_match <= is_match_reg & qualify_reg;
    end
endmodule