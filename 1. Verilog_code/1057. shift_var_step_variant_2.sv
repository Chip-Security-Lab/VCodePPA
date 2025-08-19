//SystemVerilog
// Top-level module: Hierarchical variable-step shifter with pipelined critical path
module shift_var_step #(parameter WIDTH=8) (
    input clk,
    input rst,
    input [$clog2(WIDTH)-1:0] step,
    input [WIDTH-1:0] din,
    output [WIDTH-1:0] dout
);

    // Pipeline register for input data
    reg [WIDTH-1:0] din_pipe_reg;
    reg [$clog2(WIDTH)-1:0] step_pipe_reg;

    // Pipeline register for shifted data
    reg [WIDTH-1:0] shifted_data_pipe_reg;

    // Output register
    reg [WIDTH-1:0] dout_reg;

    // Stage 1: Register inputs
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            din_pipe_reg <= {WIDTH{1'b0}};
            step_pipe_reg <= {($clog2(WIDTH)){1'b0}};
        end else begin
            din_pipe_reg <= din;
            step_pipe_reg <= step;
        end
    end

    // Stage 2: Shift operation with registered inputs
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            shifted_data_pipe_reg <= {WIDTH{1'b0}};
        end else begin
            shifted_data_pipe_reg <= din_pipe_reg << step_pipe_reg;
        end
    end

    // Stage 3: Output register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout_reg <= {WIDTH{1'b0}};
        end else begin
            dout_reg <= shifted_data_pipe_reg;
        end
    end

    assign dout = dout_reg;

endmodule