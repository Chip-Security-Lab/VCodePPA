//SystemVerilog
module even_odd_divider (
    input CLK, RESET, ODD_DIV,
    output reg DIV_CLK
);
    // Pipeline stage 1 signals
    reg [2:0] counter_stage1;
    reg half_cycle_stage1;
    reg odd_div_stage1;
    reg div_clk_stage1;
    reg terminal_count_stage1;
    
    // Pipeline stage 2 signals
    reg [2:0] counter_stage2;
    reg half_cycle_stage2;
    reg odd_div_stage2;
    reg div_clk_stage2;
    reg terminal_count_stage2;
    
    // Pipeline valid signals
    reg stage1_valid, stage2_valid;
    
    // Stage 1: Calculate terminal count and prepare next state
    always @(posedge CLK or posedge RESET) begin
        if (RESET) begin
            counter_stage1 <= 3'b000;
            half_cycle_stage1 <= 1'b0;
            div_clk_stage1 <= 1'b0;
            odd_div_stage1 <= ODD_DIV;
            terminal_count_stage1 <= 1'b0;
            stage1_valid <= 1'b0;
        end else begin
            odd_div_stage1 <= ODD_DIV;
            stage1_valid <= 1'b1;
            
            // Calculate terminal count using case statement based on odd_div_stage1
            case(odd_div_stage1)
                1'b1: terminal_count_stage1 <= (counter_stage1 == 3'b100);
                1'b0: terminal_count_stage1 <= (counter_stage1 == 3'b100);
                default: terminal_count_stage1 <= (counter_stage1 == 3'b100);
            endcase
                
            // Prepare next counter value using case statement based on terminal_count_stage1
            case(terminal_count_stage1)
                1'b1: begin
                    counter_stage1 <= 3'b000;
                    half_cycle_stage1 <= odd_div_stage1 ? ~half_cycle_stage1 : half_cycle_stage1;
                    div_clk_stage1 <= ~div_clk_stage1;
                end
                1'b0: begin
                    counter_stage1 <= counter_stage1 + 1'b1;
                end
                default: begin
                    counter_stage1 <= counter_stage1 + 1'b1;
                end
            endcase
        end
    end
    
    // Stage 2: Apply the results and generate output
    always @(posedge CLK or posedge RESET) begin
        if (RESET) begin
            counter_stage2 <= 3'b000;
            half_cycle_stage2 <= 1'b0;
            div_clk_stage2 <= 1'b0;
            odd_div_stage2 <= 1'b0;
            terminal_count_stage2 <= 1'b0;
            stage2_valid <= 1'b0;
            DIV_CLK <= 1'b0;
        end else begin
            case(stage1_valid)
                1'b1: begin
                    counter_stage2 <= counter_stage1;
                    half_cycle_stage2 <= half_cycle_stage1;
                    div_clk_stage2 <= div_clk_stage1;
                    odd_div_stage2 <= odd_div_stage1;
                    terminal_count_stage2 <= terminal_count_stage1;
                    stage2_valid <= stage1_valid;
                    
                    // Set output clock based on stage2_valid
                    case(stage2_valid)
                        1'b1: DIV_CLK <= div_clk_stage2;
                        default: DIV_CLK <= DIV_CLK;
                    endcase
                end
                default: begin
                    // No changes when stage1_valid is not high
                end
            endcase
        end
    end
endmodule