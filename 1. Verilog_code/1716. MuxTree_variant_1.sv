//SystemVerilog
module MuxTree #(parameter W=4, N=8) (
    input logic clk,
    input logic rst_n,
    input logic [N-1:0][W-1:0] din,
    input logic [$clog2(N)-1:0] sel,
    output logic [W-1:0] dout
);

    // Pipeline registers
    logic [W-1:0] stage1_reg;
    logic [W-1:0] stage2_reg;
    logic [$clog2(N)-1:0] sel_reg1;
    logic [$clog2(N)-2:0] sel_reg2;

    // Stage 1: Input register and first level mux
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_reg <= '0;
            sel_reg1 <= '0;
        end else begin
            stage1_reg <= din[sel[$clog2(N)-1] ? N/2 + sel_reg1[$clog2(N)-2:0] : sel_reg1[$clog2(N)-2:0]];
            sel_reg1 <= sel;
        end
    end

    // Stage 2: Second level mux
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_reg <= '0;
            sel_reg2 <= '0;
        end else begin
            stage2_reg <= stage1_reg;
            sel_reg2 <= sel_reg1[$clog2(N)-2:0];
        end
    end

    // Output stage
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            dout <= '0;
        else
            dout <= stage2_reg;
    end

endmodule