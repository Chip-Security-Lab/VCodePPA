//SystemVerilog
module barrel_shifter #(parameter WIDTH = 8) (
    input  wire                  clk,
    input  wire [WIDTH-1:0]      data_in,
    input  wire [2:0]            shift_amt,
    output wire [WIDTH-1:0]      data_out
);

    // Pipeline Stage 1: Register input data
    reg [WIDTH-1:0] data_pipe1;
    always @(posedge clk) begin
        data_pipe1 <= data_in;
    end

    // Pipeline Stage 1: Register shift amount
    reg [2:0] shift_pipe1;
    always @(posedge clk) begin
        shift_pipe1 <= shift_amt;
    end

    // Pipeline Stage 2: Left shift operation
    reg [WIDTH-1:0] left_shift_pipe2;
    always @(posedge clk) begin
        left_shift_pipe2 <= data_pipe1 << shift_pipe1;
    end

    // Pipeline Stage 2: Right shift operation
    reg [WIDTH-1:0] right_shift_pipe2;
    always @(posedge clk) begin
        right_shift_pipe2 <= data_pipe1 >> (WIDTH - shift_pipe1);
    end

    // Pipeline Stage 2: Register shift amount for next stage
    reg [2:0] shift_pipe2;
    always @(posedge clk) begin
        shift_pipe2 <= shift_pipe1;
    end

    // Pipeline Stage 3: Combine results
    reg [WIDTH-1:0] combined_pipe3;
    always @(posedge clk) begin
        combined_pipe3 <= left_shift_pipe2 | right_shift_pipe2;
    end

    assign data_out = combined_pipe3;

endmodule