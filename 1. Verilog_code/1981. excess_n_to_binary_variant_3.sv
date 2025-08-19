//SystemVerilog
// Top-level module: Pipelined Excess-N to Binary Converter
module excess_n_to_binary #(
    parameter WIDTH = 8,
    parameter N = 127
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire [WIDTH-1:0]       excess_n_in,
    input  wire                   data_valid_in,
    output wire [WIDTH-1:0]       binary_out,
    output wire                   data_valid_out
);

    // Stage 1: Input Register
    reg [WIDTH-1:0] excess_n_stage1;
    reg             valid_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            excess_n_stage1 <= {WIDTH{1'b0}};
            valid_stage1    <= 1'b0;
        end else if (rst_n && clk) begin
            excess_n_stage1 <= excess_n_in;
            valid_stage1    <= data_valid_in;
        end
    end

    // Stage 2: Subtraction Logic (Excess-N to Binary)
    reg [WIDTH-1:0] binary_stage2;
    reg             valid_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            binary_stage2 <= {WIDTH{1'b0}};
            valid_stage2  <= 1'b0;
        end else if (rst_n && clk) begin
            binary_stage2 <= excess_n_stage1 - N;
            valid_stage2  <= valid_stage1;
        end
    end

    // Stage 3: Output Register
    reg [WIDTH-1:0] binary_out_reg;
    reg             data_valid_out_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            binary_out_reg     <= {WIDTH{1'b0}};
            data_valid_out_reg <= 1'b0;
        end else if (rst_n && clk) begin
            binary_out_reg     <= binary_stage2;
            data_valid_out_reg <= valid_stage2;
        end
    end

    assign binary_out     = binary_out_reg;
    assign data_valid_out = data_valid_out_reg;

endmodule