//SystemVerilog
// SystemVerilog
// Module for combinational inversion
module inverter (
    input wire data_in,
    output wire data_out
);
    assign data_out = ~data_in;
endmodule

// Module for asynchronous reset logic (Combinational part)
module async_reset_comb (
    input wire reset,
    input wire data_in,
    output wire data_out_comb
);
    assign data_out_comb = reset ? 1'b0 : data_in;
endmodule

// Module for asynchronous reset logic (Sequential part)
module async_reset_seq (
    input wire data_in_comb,
    input wire clk, // Clock is added for sequential logic
    output reg data_out_reg
);
    always @(posedge clk) begin // Sequential logic triggered by clock
        data_out_reg <= data_in_comb;
    end
endmodule

// Top-level module combining inversion and asynchronous reset with sequential output
module not_gate_async_reset (
    input wire A,
    input wire clk,
    input wire reset,
    output wire Y
);

    wire inverted_A;
    wire reset_applied_comb;
    wire reset_applied_reg;

    // Instantiate the inverter submodule (Combinational)
    inverter u_inverter (
        .data_in(A),
        .data_out(inverted_A)
    );

    // Instantiate the asynchronous reset logic combinational part
    async_reset_comb u_async_reset_comb (
        .reset(reset),
        .data_in(inverted_A),
        .data_out_comb(reset_applied_comb)
    );

    // Instantiate the asynchronous reset logic sequential part
    // Note: This implements a synchronous output register after the asynchronous reset combinational logic.
    // If a truly asynchronous output is required, async_reset_logic module should be used directly.
    // This structure provides a registered output, potentially improving timing characteristics.
    async_reset_seq u_async_reset_seq (
        .data_in_comb(reset_applied_comb),
        .clk(clk),
        .data_out_reg(reset_applied_reg)
    );

    // Assign the final output from the registered value
    assign Y = reset_applied_reg;

endmodule

// Original asynchronous reset logic (kept for reference if a purely asynchronous output is needed)
/*
module async_reset_logic (
    input wire reset,
    input wire data_in,
    output reg data_out
);
    always @(posedge reset or posedge data_in) begin // Note: This creates a latch due to data_in in sensitivity list without clock
        if (reset) begin
            data_out <= 0;
        end else begin
            data_out <= data_in;
        end
    end
endmodule
*/