//SystemVerilog
module mux_sync_reset (
    input wire clk,                   // Clock input
    input wire rst,                   // Synchronous reset
    input wire [7:0] input_0, input_1, // Data inputs
    input wire sel_line,              // Selection input
    output reg [7:0] mux_result       // Registered output
);

    reg [7:0] input_0_reg;
    reg [7:0] input_1_reg;
    reg sel_line_reg;

    always @(posedge clk) begin
        if (rst) begin
            input_0_reg <= 8'b0;
            input_1_reg <= 8'b0;
            sel_line_reg <= 1'b0;
        end else begin
            input_0_reg <= input_0;
            input_1_reg <= input_1;
            sel_line_reg <= sel_line;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            mux_result <= 8'b0;
        end else begin
            if (sel_line_reg) begin
                mux_result <= input_1_reg;
            end else begin
                mux_result <= input_0_reg;
            end
        end
    end

endmodule