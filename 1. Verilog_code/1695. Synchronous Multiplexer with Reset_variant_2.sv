//SystemVerilog
// Top-level module
module sync_mux_with_reset(
    input clk, rst_n,
    input [31:0] data_a, data_b,
    input sel, en,
    output [31:0] result
);
    wire [31:0] mux_result;

    // Instantiate the multiplexer submodule
    mux mux_inst (
        .clk(clk),
        .rst_n(rst_n),
        .data_a(data_a),
        .data_b(data_b),
        .sel(sel),
        .en(en),
        .result(mux_result)
    );

    // Register to hold the result with reset functionality
    result_register result_reg (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .mux_result(mux_result),
        .result(result)
    );
endmodule

// Submodule for the multiplexer
module mux(
    input clk, rst_n,
    input [31:0] data_a, data_b,
    input sel, en,
    output reg [31:0] result
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= 32'h0;
        end else if (en) begin
            if (sel) begin
                result <= data_b;
            end else begin
                result <= data_a;
            end
        end
    end
endmodule

// Submodule for the result register
module result_register(
    input clk, rst_n,
    input en,
    input [31:0] mux_result,
    output reg [31:0] result
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= 32'h0;
        end else if (en) begin
            result <= mux_result;
        end
    end
endmodule