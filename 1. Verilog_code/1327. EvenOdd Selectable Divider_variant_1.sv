//SystemVerilog
module even_odd_divider (
    input wire CLK,
    input wire RESET,
    input wire ODD_DIV,
    output wire DIV_CLK
);
    // Internal connections
    wire terminal_count;
    wire [2:0] counter;
    wire half_cycle;

    // Instance input_stage module
    input_stage u_input_stage (
        .CLK(CLK),
        .RESET(RESET),
        .ODD_DIV(ODD_DIV),
        .counter(counter),
        .half_cycle(half_cycle),
        .terminal_count(terminal_count)
    );

    // Instance counter_control module
    counter_control u_counter_control (
        .CLK(CLK),
        .RESET(RESET),
        .terminal_count(terminal_count),
        .ODD_DIV(ODD_DIV),
        .counter(counter),
        .half_cycle(half_cycle),
        .DIV_CLK(DIV_CLK)
    );
endmodule

// Input stage module - handles input registration and comparisons
module input_stage (
    input wire CLK,
    input wire RESET,
    input wire ODD_DIV,
    input wire [2:0] counter,
    input wire half_cycle,
    output reg terminal_count
);
    // Pipeline registers for critical path optimization
    reg odd_div_r;
    reg counter_comp_r;
    reg half_cycle_r;
    
    // First stage: Register inputs and comparisons
    always @(posedge CLK or posedge RESET) begin
        if (RESET) begin
            odd_div_r <= 1'b0;
            counter_comp_r <= 1'b0;
            half_cycle_r <= 1'b0;
        end else begin
            odd_div_r <= ODD_DIV;
            counter_comp_r <= (counter == 3'b100);
            half_cycle_r <= half_cycle;
        end
    end
    
    // Second stage: Calculate terminal_count with reduced critical path
    always @(posedge CLK or posedge RESET) begin
        if (RESET) begin
            terminal_count <= 1'b0;
        end else begin
            terminal_count <= counter_comp_r;
        end
    end
endmodule

// Counter control module - manages counter and output clock generation
module counter_control (
    input wire CLK,
    input wire RESET,
    input wire terminal_count,
    input wire ODD_DIV,
    output reg [2:0] counter,
    output reg half_cycle,
    output reg DIV_CLK
);
    // Main counter logic
    always @(posedge CLK or posedge RESET) begin
        if (RESET) begin
            counter <= 3'b000;
            half_cycle <= 1'b0;
            DIV_CLK <= 1'b0;
        end else if (terminal_count) begin
            counter <= 3'b000;
            half_cycle <= ODD_DIV ? ~half_cycle : half_cycle;
            DIV_CLK <= ~DIV_CLK;
        end else
            counter <= counter + 1'b1;
    end
endmodule