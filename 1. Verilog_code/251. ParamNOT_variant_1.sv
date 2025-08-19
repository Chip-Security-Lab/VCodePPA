//SystemVerilog
// SystemVerilog
// Top module for the parameterized NOT operation with pipelining
module ParamNOT_Top_Pipelined #(parameter WIDTH = 8) (
    input clk,
    input rst_n,
    input [WIDTH-1:0] data_in,
    output [WIDTH-1:0] data_out
);

    // Internal signal for the pipelined data
    logic [WIDTH-1:0] data_in_reg;
    logic [WIDTH-1:0] not_result_reg;

    // Pipeline stage 1: Register input data
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_reg <= '0;
        end else begin
            data_in_reg <= data_in;
        end
    end

    // Instantiate the core NOT logic submodule
    ParamNOT_Core_Pipelined #(
        .WIDTH(WIDTH)
    ) u_param_not_core (
        .input_data(data_in_reg),
        .output_data(not_result_reg) // Output of the core logic is registered
    );

    // Pipeline stage 2: Output registered result
    // This stage is effectively implemented by the core module's output register

    // Assign the final output
    assign data_out = not_result_reg;

endmodule

// Submodule implementing the core parameterized NOT logic with output register
module ParamNOT_Core_Pipelined #(parameter WIDTH = 8) (
    input clk,
    input rst_n,
    input [WIDTH-1:0] input_data,
    output logic [WIDTH-1:0] output_data // Output is a registered signal
);

    // Internal wire for the combinatorial NOT result
    wire [WIDTH-1:0] not_comb_result;

    // Perform the bitwise NOT operation (combinatorial)
    assign not_comb_result = ~input_data;

    // Register the combinatorial result
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            output_data <= '0;
        end else begin
            output_data <= not_comb_result;
        end
    end

endmodule