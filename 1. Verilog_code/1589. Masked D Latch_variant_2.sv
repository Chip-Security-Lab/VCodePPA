//SystemVerilog
module masked_d_latch (
    input wire clk,
    input wire rst_n,
    input wire [7:0] d_in,
    input wire [7:0] mask,
    input wire enable,
    output reg [7:0] q_out
);

    // Internal signals for data path stages
    reg [7:0] masked_data;
    reg [7:0] preserved_data;
    reg [7:0] next_q_out;

    // Stage 1: Mask application - Apply mask to input data
    always @* begin
        masked_data = d_in & mask;
    end

    // Stage 1: Mask application - Preserve unmasked bits
    always @* begin
        preserved_data = q_out & ~mask;
    end

    // Stage 2: Data combination - Combine masked and preserved data
    always @* begin
        next_q_out = masked_data | preserved_data;
    end

    // Stage 3: Register update - Handle reset and enable conditions
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q_out <= 8'b0;
        else if (enable)
            q_out <= next_q_out;
    end

endmodule