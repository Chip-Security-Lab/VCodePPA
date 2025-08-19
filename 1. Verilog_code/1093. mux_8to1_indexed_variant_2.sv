//SystemVerilog
module mux_8to1_indexed (
    input wire         clk,            // Clock for pipelining
    input wire [7:0]   inputs,         // 8 data inputs
    input wire [2:0]   selector,       // 3-bit selector
    output wire        out             // Output
);

    // Input Register Stage
    reg [7:0]   inputs_reg;
    reg [2:0]   selector_reg;
    always @(posedge clk) begin
        inputs_reg <= inputs;
    end
    always @(posedge clk) begin
        selector_reg <= selector;
    end

    // Selector Decode Stage
    reg [7:0]   selector_onehot_reg;
    always @(posedge clk) begin
        selector_onehot_reg <= 8'b00000001 << selector_reg;
    end

    // Data Masking Stage
    reg [7:0]   masked_inputs_reg;
    always @(posedge clk) begin
        masked_inputs_reg <= inputs_reg & selector_onehot_reg;
    end

    // Output Generation Stage
    reg         out_reg;
    always @(posedge clk) begin
        out_reg <= |masked_inputs_reg;
    end

    // Final Output Assignment
    assign out = out_reg;

endmodule