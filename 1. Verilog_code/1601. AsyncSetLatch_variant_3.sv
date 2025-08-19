//SystemVerilog
module AsyncSetLatch #(parameter W=8) (
    input wire clk,
    input wire set,
    input wire [W-1:0] d,
    output reg [W-1:0] q
);

    // Data path pipeline registers
    reg [W-1:0] data_reg;
    reg [W-1:0] set_reg;

    // First pipeline stage - data capture
    always @(posedge clk) begin
        data_reg <= d;
    end

    // Second pipeline stage - set control
    always @(posedge clk) begin
        set_reg <= {W{set}};
    end

    // Final stage - output generation
    always @(posedge clk or posedge set) begin
        if (set) begin
            q <= {W{1'b1}};
        end else begin
            q <= data_reg;
        end
    end

endmodule