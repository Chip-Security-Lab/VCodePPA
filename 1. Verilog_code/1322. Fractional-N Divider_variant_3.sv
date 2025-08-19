//SystemVerilog
// Top level module
module fractional_n_div #(
    parameter INT_DIV = 4,
    parameter FRAC_DIV = 3,
    parameter FRAC_BITS = 4
) (
    input wire clk_src,
    input wire reset_n,
    output wire clk_out
);
    // Internal signals for connecting submodules
    wire frac_overflow;
    wire counter_tc;
    wire [FRAC_BITS-1:0] frac_acc;
    
    // Fractional accumulator submodule
    frac_accumulator #(
        .FRAC_DIV(FRAC_DIV),
        .FRAC_BITS(FRAC_BITS)
    ) frac_acc_inst (
        .clk_src(clk_src),
        .reset_n(reset_n),
        .enable(counter_tc),
        .frac_acc(frac_acc),
        .frac_overflow(frac_overflow)
    );
    
    // Counter submodule
    int_counter #(
        .INT_DIV(INT_DIV)
    ) counter_inst (
        .clk_src(clk_src),
        .reset_n(reset_n),
        .frac_overflow(frac_overflow),
        .counter_tc(counter_tc)
    );
    
    // Clock output generator
    clk_generator clk_gen_inst (
        .clk_src(clk_src),
        .reset_n(reset_n),
        .counter_tc(counter_tc),
        .clk_out(clk_out)
    );
endmodule

// Fractional accumulator module
module frac_accumulator #(
    parameter FRAC_DIV = 3,
    parameter FRAC_BITS = 4
) (
    input wire clk_src,
    input wire reset_n,
    input wire enable,
    output reg [FRAC_BITS-1:0] frac_acc,
    output wire frac_overflow
);
    wire [FRAC_BITS:0] next_acc_value;
    reg [FRAC_BITS-1:0] acc_update_value;
    
    // Calculate if the next accumulation will cause an overflow
    assign next_acc_value = frac_acc + FRAC_DIV;
    assign frac_overflow = next_acc_value >= (1 << FRAC_BITS);
    
    // Calculate the update value for accumulator
    always @(*) begin
        if (frac_overflow) begin
            acc_update_value = next_acc_value - (1 << FRAC_BITS);
        end else begin
            acc_update_value = next_acc_value[FRAC_BITS-1:0];
        end
    end
    
    // Reset logic
    always @(negedge reset_n) begin
        if (!reset_n) begin
            frac_acc <= 0;
        end
    end
    
    // Accumulator update logic
    always @(posedge clk_src) begin
        if (reset_n && enable) begin
            frac_acc <= acc_update_value;
        end
    end
endmodule

// Integer counter module
module int_counter #(
    parameter INT_DIV = 4
) (
    input wire clk_src,
    input wire reset_n,
    input wire frac_overflow,
    output wire counter_tc
);
    reg [3:0] counter;
    wire [3:0] terminal_count;
    
    // Terminal count depends on fractional overflow
    assign terminal_count = (frac_overflow ? INT_DIV : INT_DIV-1) - 1;
    assign counter_tc = (counter == terminal_count);
    
    // Reset logic
    always @(negedge reset_n) begin
        if (!reset_n) begin
            counter <= 0;
        end
    end
    
    // Counter increment logic
    always @(posedge clk_src) begin
        if (reset_n && !counter_tc) begin
            counter <= counter + 1;
        end
    end
    
    // Counter reset logic on terminal count
    always @(posedge clk_src) begin
        if (reset_n && counter_tc) begin
            counter <= 0;
        end
    end
endmodule

// Clock output generator module
module clk_generator (
    input wire clk_src,
    input wire reset_n,
    input wire counter_tc,
    output reg clk_out
);
    // Reset logic
    always @(negedge reset_n) begin
        if (!reset_n) begin
            clk_out <= 0;
        end
    end
    
    // Clock toggle logic
    always @(posedge clk_src) begin
        if (reset_n && counter_tc) begin
            clk_out <= ~clk_out;
        end
    end
endmodule