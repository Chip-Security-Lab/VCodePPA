//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// File: programmable_clk_gen_top.v
// Description: Programmable clock generator top module with hierarchical design
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////

module programmable_clk_gen(
    input wire sys_clk,        // System clock
    input wire sys_rst_n,      // System reset (active low)
    input wire [15:0] divisor, // Clock divisor value
    input wire update,         // Update divisor value
    output wire clk_out        // Output clock
);
    // Internal signals
    wire [15:0] div_value;
    wire [15:0] div_counter;
    wire toggle_clk;

    // Divisor register management submodule
    divisor_manager u_divisor_manager (
        .sys_clk     (sys_clk),
        .sys_rst_n   (sys_rst_n),
        .divisor     (divisor),
        .update      (update),
        .div_value   (div_value)
    );

    // Counter logic submodule
    counter_logic u_counter_logic (
        .sys_clk     (sys_clk),
        .sys_rst_n   (sys_rst_n),
        .div_value   (div_value),
        .div_counter (div_counter),
        .toggle_clk  (toggle_clk)
    );

    // Clock output generation submodule
    clock_output u_clock_output (
        .sys_clk     (sys_clk),
        .sys_rst_n   (sys_rst_n),
        .toggle_clk  (toggle_clk),
        .clk_out     (clk_out)
    );

endmodule

///////////////////////////////////////////////////////////////////////////////
// Divisor Manager: Handles divisor updates and storage
///////////////////////////////////////////////////////////////////////////////

module divisor_manager (
    input wire sys_clk,
    input wire sys_rst_n,
    input wire [15:0] divisor,
    input wire update,
    output reg [15:0] div_value
);
    // Reset handling for divisor value
    always @(negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            div_value <= 16'd1;  // Default value to avoid division by zero
        end
    end

    // Update divisor value on update signal
    always @(posedge sys_clk) begin
        if (sys_rst_n && update) begin
            div_value <= (divisor == 16'd0) ? 16'd1 : divisor;  // Protection against zero
        end
    end
endmodule

///////////////////////////////////////////////////////////////////////////////
// Counter Logic: Implements the division counter
///////////////////////////////////////////////////////////////////////////////

module counter_logic (
    input wire sys_clk,
    input wire sys_rst_n,
    input wire [15:0] div_value,
    output reg [15:0] div_counter,
    output reg toggle_clk
);
    // Reset handling for counter and toggle signal
    always @(negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            div_counter <= 16'd0;
            toggle_clk <= 1'b0;
        end
    end

    // Counter increment logic
    always @(posedge sys_clk) begin
        if (sys_rst_n) begin
            if (div_counter >= div_value - 16'd1) begin
                div_counter <= 16'd0;
            end else begin
                div_counter <= div_counter + 16'd1;
            end
        end
    end

    // Toggle clock generation logic
    always @(posedge sys_clk) begin
        if (sys_rst_n) begin
            if (div_counter >= div_value - 16'd1) begin
                toggle_clk <= 1'b1;
            end else begin
                toggle_clk <= 1'b0;
            end
        end
    end
endmodule

///////////////////////////////////////////////////////////////////////////////
// Clock Output: Generates the final output clock
///////////////////////////////////////////////////////////////////////////////

module clock_output (
    input wire sys_clk,
    input wire sys_rst_n,
    input wire toggle_clk,
    output reg clk_out
);
    // Reset handling for output clock
    always @(negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            clk_out <= 1'b0;
        end
    end

    // Toggle output clock based on toggle_clk signal
    always @(posedge sys_clk) begin
        if (sys_rst_n && toggle_clk) begin
            clk_out <= ~clk_out;
        end
    end
endmodule