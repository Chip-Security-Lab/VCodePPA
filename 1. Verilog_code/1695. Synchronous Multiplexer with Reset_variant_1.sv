//SystemVerilog
module sync_mux_with_reset(
    input clk,
    input rst_n,
    input [31:0] data_a,
    input [31:0] data_b,
    input sel,
    input valid,
    output reg ready,
    output reg [31:0] result
);

    reg [31:0] data_reg;
    reg sel_reg;
    reg valid_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= 32'h0;
            ready <= 1'b0;
            data_reg <= 32'h0;
            sel_reg <= 1'b0;
            valid_reg <= 1'b0;
        end else begin
            if (valid && ready) begin
                result <= sel_reg ? data_b : data_a;
                ready <= 1'b0;
            end else if (!valid) begin
                ready <= 1'b1;
                data_reg <= data_a;
                sel_reg <= sel;
                valid_reg <= valid;
            end
        end
    end
endmodule