//SystemVerilog
//IEEE 1364-2005 Verilog
module float2int #(parameter INT_BITS = 32) (
    input wire clk, rst_n,
    input wire [31:0] float_in,  // IEEE-754 Single precision
    output reg signed [INT_BITS-1:0] int_out,
    output reg overflow
);

    // Move registers after combinational logic (retiming)
    wire sign_wire;
    wire [7:0] exponent_wire;
    wire [22:0] mantissa_wire;

    assign sign_wire = float_in[31];
    assign exponent_wire = float_in[30:23];
    assign mantissa_wire = float_in[22:0];

    // Combinational logic for shifted value and overflow, based on input fields
    wire [23:0] mantissa_with_hidden_bit_wire;
    assign mantissa_with_hidden_bit_wire = {1'b1, mantissa_wire};

    wire [7:0] exponent_bias_adj_wire;
    assign exponent_bias_adj_wire = exponent_wire - 8'd127;

    wire [INT_BITS-1:0] shifted_value_wire;
    assign shifted_value_wire = (exponent_bias_adj_wire < 8'd24) ?
        (mantissa_with_hidden_bit_wire >> (8'd23 - exponent_bias_adj_wire)) :
        (mantissa_with_hidden_bit_wire << (exponent_bias_adj_wire - 8'd23));

    wire overflow_wire;
    assign overflow_wire = (exponent_wire > (127 + INT_BITS - 1));

    // Register the combinational results after logic
    reg sign_reg_d;
    reg [INT_BITS-1:0] shifted_value_reg_d;
    reg overflow_reg_d;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sign_reg_d <= 1'b0;
            shifted_value_reg_d <= {INT_BITS{1'b0}};
            overflow_reg_d <= 1'b0;
        end else begin
            sign_reg_d <= sign_wire;
            shifted_value_reg_d <= shifted_value_wire;
            overflow_reg_d <= overflow_wire;
        end
    end

    // Output logic: registered assignment, as all combinational logic is retimed before this stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_out <= {INT_BITS{1'b0}};
            overflow <= 1'b0;
        end else begin
            overflow <= overflow_reg_d;
            if (!overflow_reg_d) begin
                int_out <= sign_reg_d ? -shifted_value_reg_d : shifted_value_reg_d;
            end else begin
                int_out <= sign_reg_d ? {1'b1, {(INT_BITS-1){1'b0}}} : {1'b0, {(INT_BITS-1){1'b1}}};
            end
        end
    end

endmodule