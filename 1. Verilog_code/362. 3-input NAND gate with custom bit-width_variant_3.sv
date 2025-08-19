//SystemVerilog
module nand3_4 (
    input  wire        clk,
    input  wire [3:0]  A,
    input  wire [3:0]  B,
    input  wire [3:0]  C,
    output wire [3:0]  Y
);

// Stage 1: Input registration
reg [3:0] A_reg;
reg [3:0] B_reg;
reg [3:0] C_reg;

always @(posedge clk) begin
    A_reg <= A;
    B_reg <= B;
    C_reg <= C;
end

// Stage 2: Inversion stage
reg [3:0] A_inv_stage;
reg [3:0] B_inv_stage;
reg [3:0] C_inv_stage;

always @(posedge clk) begin
    A_inv_stage <= ~A_reg;
    B_inv_stage <= ~B_reg;
    C_inv_stage <= ~C_reg;
end

// Stage 3: OR-combine stage
reg [3:0] Y_pipeline;

always @(posedge clk) begin
    Y_pipeline <= A_inv_stage | B_inv_stage | C_inv_stage;
end

// Output
assign Y = Y_pipeline;

endmodule