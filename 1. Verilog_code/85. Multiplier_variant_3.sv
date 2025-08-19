//SystemVerilog
// Control module for ready signal generation
module MultiplierControl(
    input clk,
    input rst_n,
    input calc_valid,
    output reg ready
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            ready <= 1'b0;
        else
            ready <= !calc_valid;
    end

endmodule

// Data path module for multiplication
module MultiplierDataPath(
    input clk,
    input rst_n,
    input valid,
    input ready,
    input [7:0] in_a,
    input [7:0] in_b,
    output reg calc_valid,
    output reg [15:0] out
);

    reg [7:0] a_reg, b_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 8'b0;
            b_reg <= 8'b0;
            calc_valid <= 1'b0;
            out <= 16'b0;
        end
        else begin
            if (valid && ready) begin
                a_reg <= in_a;
                b_reg <= in_b;
                calc_valid <= 1'b1;
            end
            else if (calc_valid) begin
                out <= a_reg * b_reg;
                calc_valid <= 1'b0;
            end
        end
    end

endmodule

// Top-level module
module Multiplier5(
    input clk,
    input rst_n,
    input valid,
    input [7:0] in_a,
    input [7:0] in_b,
    output ready,
    output [15:0] out
);

    wire calc_valid;

    // Instantiate control module
    MultiplierControl control_unit(
        .clk(clk),
        .rst_n(rst_n),
        .calc_valid(calc_valid),
        .ready(ready)
    );

    // Instantiate data path module
    MultiplierDataPath data_path(
        .clk(clk),
        .rst_n(rst_n),
        .valid(valid),
        .ready(ready),
        .in_a(in_a),
        .in_b(in_b),
        .calc_valid(calc_valid),
        .out(out)
    );

endmodule