//SystemVerilog
module enabled_reset_sync (
    input  wire clk_in,
    input  wire rst_in_n,
    input  wire enable,
    output reg  rst_out_n
);

    reg metastable_reg;
    wire rst_sync;
    wire enable_sync;

    // Synchronized reset and enable signals
    assign rst_sync    = rst_in_n;
    assign enable_sync = enable;

    // Balanced logic for metastable register
    always @(posedge clk_in or negedge rst_sync) begin
        if (!rst_sync) begin
            metastable_reg <= 1'b0;
        end else begin
            metastable_reg <= enable_sync | metastable_reg;
        end
    end

    // Balanced logic for output reset
    always @(posedge clk_in or negedge rst_sync) begin
        if (!rst_sync) begin
            rst_out_n <= 1'b0;
        end else begin
            rst_out_n <= enable_sync ? metastable_reg : rst_out_n;
        end
    end

endmodule