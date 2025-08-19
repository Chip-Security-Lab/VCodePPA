//SystemVerilog
module shift_arith_right #(parameter WIDTH=8) (
    input wire                  clk,
    input wire                  rst_n,
    input wire [WIDTH-1:0]      data_in,
    input wire [2:0]            shift_amount,
    output reg [WIDTH-1:0]      data_out
);

// ====================================================================
// Pipeline Stage 1: Input Registering (registers moved after input)
// ====================================================================
reg [WIDTH-1:0] data_in_reg;
reg [2:0]       shift_amount_reg;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_in_reg      <= {WIDTH{1'b0}};
        shift_amount_reg <= 3'b000;
    end else begin
        data_in_reg      <= data_in;
        shift_amount_reg <= shift_amount;
    end
end

// ====================================================================
// Pipeline Stage 2: Arithmetic Shift Calculation (combinational)
// ====================================================================
wire signed [WIDTH-1:0] shift_result_comb;
assign shift_result_comb = $signed(data_in_reg) >>> shift_amount_reg;

// ====================================================================
// Pipeline Stage 3: Output Registering
// ====================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_out <= {WIDTH{1'b0}};
    end else begin
        data_out <= shift_result_comb;
    end
end

endmodule