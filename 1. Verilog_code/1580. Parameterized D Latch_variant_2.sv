//SystemVerilog
module param_d_latch #(
    parameter WIDTH = 8
)(
    input wire [WIDTH-1:0] data_in,
    input wire enable,
    output reg [WIDTH-1:0] data_out
);

    // Internal register for data storage
    reg [WIDTH-1:0] data_reg;
    reg [WIDTH-1:0] next_data;

    // Data path stage 1: Input sampling with improved timing
    always @* begin
        next_data = enable ? data_in : data_reg;
    end

    // Data path stage 2: Register update
    always @(posedge enable) begin
        data_reg <= next_data;
    end

    // Data path stage 3: Output generation
    always @* begin
        data_out = data_reg;
    end

endmodule