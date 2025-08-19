//SystemVerilog
module nor4_pipeline (
    input  wire clk,
    input  wire rst_n,
    input  wire A_in,
    input  wire B_in,
    input  wire C_in,
    input  wire D_in,
    output wire Y_out
);

// Stage 1: Input Registering and Inversion
reg A_n_stage1, B_n_stage1, C_n_stage1, D_n_stage1;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        A_n_stage1 <= 1'b0;
        B_n_stage1 <= 1'b0;
        C_n_stage1 <= 1'b0;
        D_n_stage1 <= 1'b0;
    end else begin
        A_n_stage1 <= ~A_in;
        B_n_stage1 <= ~B_in;
        C_n_stage1 <= ~C_in;
        D_n_stage1 <= ~D_in;
    end
end

// Stage 2: All AND Operations and Output Registering
reg Y_stage2;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        Y_stage2 <= 1'b0;
    end else begin
        Y_stage2 <= (A_n_stage1 & B_n_stage1) & (C_n_stage1 & D_n_stage1);
    end
end

assign Y_out = Y_stage2;

endmodule