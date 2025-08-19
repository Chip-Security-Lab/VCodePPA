//SystemVerilog
module config_timer #(
    parameter DATA_WIDTH = 24,
    parameter PRESCALE_WIDTH = 8
)(
    input clk_i, rst_i, enable_i,
    input [DATA_WIDTH-1:0] period_i,
    input [PRESCALE_WIDTH-1:0] prescaler_i,
    output reg [DATA_WIDTH-1:0] value_o,
    output expired_o
);
    // Pipeline registers for prescaler and period comparison
    reg [PRESCALE_WIDTH-1:0] prescale_counter;
    reg prescale_tick_stage1, prescale_tick_stage2;
    reg period_match_stage1, period_match_stage2;
    
    // Pipeline registers for computation
    reg [PRESCALE_WIDTH-1:0] prescaler_minus_one;
    reg [DATA_WIDTH-1:0] period_minus_one;
    
    // Enable signal pipeline
    reg enable_pipe;
    
    // Pre-calculation stage - breaking critical path
    always @(posedge clk_i) begin
        if (rst_i) begin
            prescaler_minus_one <= {PRESCALE_WIDTH{1'b0}};
            period_minus_one <= {DATA_WIDTH{1'b0}};
            enable_pipe <= 1'b0;
        end else begin
            prescaler_minus_one <= prescaler_i - 1'b1;
            period_minus_one <= period_i - 1'b1;
            enable_pipe <= enable_i;
        end
    end
    
    // First comparison stage
    always @(posedge clk_i) begin
        if (rst_i) begin
            prescale_tick_stage1 <= 1'b0;
            period_match_stage1 <= 1'b0;
        end else if (enable_pipe) begin
            prescale_tick_stage1 <= (prescale_counter == prescaler_minus_one);
            period_match_stage1 <= (value_o == period_minus_one);
        end else begin
            prescale_tick_stage1 <= 1'b0;
            period_match_stage1 <= 1'b0;
        end
    end
    
    // Second pipeline stage - register comparison results
    always @(posedge clk_i) begin
        if (rst_i) begin
            prescale_tick_stage2 <= 1'b0;
            period_match_stage2 <= 1'b0;
        end else begin
            prescale_tick_stage2 <= prescale_tick_stage1;
            period_match_stage2 <= period_match_stage1;
        end
    end
    
    // Counter update logic
    always @(posedge clk_i) begin
        if (rst_i) begin
            value_o <= {DATA_WIDTH{1'b0}};
            prescale_counter <= {PRESCALE_WIDTH{1'b0}};
        end else if (enable_pipe) begin
            if (prescale_tick_stage2) begin
                prescale_counter <= {PRESCALE_WIDTH{1'b0}};
                if (period_match_stage2) begin
                    value_o <= {DATA_WIDTH{1'b0}};
                end else begin
                    value_o <= value_o + 1'b1;
                end
            end else begin
                prescale_counter <= prescale_counter + 1'b1;
            end
        end
    end
    
    // Pipelined output logic
    reg expired_reg;
    always @(posedge clk_i) begin
        if (rst_i) begin
            expired_reg <= 1'b0;
        end else begin
            expired_reg <= period_match_stage2 && prescale_tick_stage2 && enable_pipe;
        end
    end
    
    assign expired_o = expired_reg;
    
endmodule