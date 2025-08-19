//SystemVerilog
// SystemVerilog
module even_odd_divider (
    input CLK, RESET, ODD_DIV,
    output reg DIV_CLK
);
    reg [2:0] counter;
    reg half_cycle;
    
    // Pipeline registers to split combinational logic
    reg odd_div_reg;
    reg counter_eq_3;
    reg terminal_count_stage1;
    reg terminal_count_reg;
    
    // Register input to reduce fan-in delay
    always @(posedge CLK or posedge RESET) begin
        if (RESET) begin
            odd_div_reg <= 1'b0;
            counter_eq_3 <= 1'b0;
        end else begin
            odd_div_reg <= ODD_DIV;
            counter_eq_3 <= (counter == 3'b011);
        end
    end
    
    // First pipeline stage for terminal count computation
    always @(posedge CLK or posedge RESET) begin
        if (RESET) begin
            terminal_count_stage1 <= 1'b0;
        end else begin
            terminal_count_stage1 <= odd_div_reg ? 
                        (counter_eq_3) : 
                        (counter_eq_3);
        end
    end
    
    // Second pipeline stage to complete terminal count
    always @(posedge CLK or posedge RESET) begin
        if (RESET) begin
            terminal_count_reg <= 1'b0;
        end else begin
            terminal_count_reg <= odd_div_reg ? 
                        (terminal_count_stage1 && (half_cycle || !half_cycle)) :
                        terminal_count_stage1;
        end
    end
    
    // Main counter and output logic
    always @(posedge CLK or posedge RESET) begin
        if (RESET) begin
            counter <= 3'b000;
            half_cycle <= 1'b0;
            DIV_CLK <= 1'b0;
        end else if (terminal_count_reg) begin
            counter <= 3'b000;
            half_cycle <= odd_div_reg ? ~half_cycle : half_cycle;
            DIV_CLK <= ~DIV_CLK;
        end else begin
            counter <= counter + 1'b1;
        end
    end
endmodule