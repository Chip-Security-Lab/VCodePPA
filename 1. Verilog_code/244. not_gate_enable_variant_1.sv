//SystemVerilog
// SystemVerilog
module not_gate_enable_pipeline (
    input wire clk,
    input wire rst_n,
    input wire A_in,
    input wire enable_in,
    output wire Y_out
);

// Stage 1: Input Register
reg A_reg;
reg enable_reg;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        A_reg <= 1'b0;
        enable_reg <= 1'b0;
    end else begin
        A_reg <= A_in;
        enable_reg <= enable_in;
    end
end

// Stage 2: Logic and Output Register
reg Y_reg;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        Y_reg <= 1'b0; // Or 1'bz depending on reset requirement
    end else begin
        if (enable_reg) begin
            Y_reg <= ~A_reg;
        end else begin
            Y_reg <= 1'bz;
        end
    end
end

// Output Assignment
assign Y_out = Y_reg;

endmodule