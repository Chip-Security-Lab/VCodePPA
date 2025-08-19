//SystemVerilog
module binary_to_thermometer #(
    parameter BINARY_WIDTH = 3
)(
    input  wire                          clk,
    input  wire                          rst_n,
    input  wire [BINARY_WIDTH-1:0]       binary_in,
    output reg  [2**BINARY_WIDTH-2:0]    thermo_out
);

    // Stage 1: Register input
    reg [BINARY_WIDTH-1:0] binary_in_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            binary_in_stage1 <= {BINARY_WIDTH{1'b0}};
        else
            binary_in_stage1 <= binary_in;
    end

    // Stage 2: Compute thermometer vector (combinational)
    reg [2**BINARY_WIDTH-2:0] thermo_vector_stage2;
    integer i;
    always @* begin : thermometer_encode_stage
        for (i = 0; i < 2**BINARY_WIDTH-1; i = i + 1) begin
            thermo_vector_stage2[i] = (i < binary_in_stage1) ? 1'b1 : 1'b0;
        end
    end

    // Stage 3: Register output (pipeline)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            thermo_out <= {(2**BINARY_WIDTH-1){1'b0}};
        else
            thermo_out <= thermo_vector_stage2;
    end

endmodule