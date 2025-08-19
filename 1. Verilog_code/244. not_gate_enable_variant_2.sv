//SystemVerilog
module not_gate_enable_pipe (
    input wire clk,
    input wire rst_n,
    input wire A_in,
    input wire enable_in,
    output wire Y_out
);

    // Pipeline registers
    reg A_reg;
    reg enable_reg;
    reg not_A_reg;

    // Combinational logic stage 1: Register inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            A_reg <= 1'b0;
            enable_reg <= 1'b0;
        end else begin
            A_reg <= A_in;
            enable_reg <= enable_in;
        end
    end

    // Combinational logic stage 2: Perform NOT operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            not_A_reg <= 1'b0;
        end else begin
            not_A_reg <= ~A_reg;
        end
    end

    // Combinational logic stage 3: Apply enable and output
    assign Y_out = enable_reg ? not_A_reg : 1'bz;

endmodule