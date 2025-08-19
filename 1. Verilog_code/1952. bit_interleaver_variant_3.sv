//SystemVerilog
module bit_interleaver #(
    parameter WIDTH = 8
)(
    input                  clk,
    input                  rst_n,
    input  [WIDTH-1:0]     data_a,
    input  [WIDTH-1:0]     data_b,
    input                  valid_in,
    output reg [2*WIDTH-1:0] interleaved_data,
    output reg             valid_out
);

    // Stage 1: Register input data for pipeline
    reg [WIDTH-1:0] data_a_reg;
    reg [WIDTH-1:0] data_b_reg;
    reg             valid_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_a_reg <= {WIDTH{1'b0}};
            data_b_reg <= {WIDTH{1'b0}};
            valid_reg  <= 1'b0;
        end else begin
            data_a_reg <= data_a;
            data_b_reg <= data_b;
            valid_reg  <= valid_in;
        end
    end

    // Stage 2: Optimized interleaving logic (combinational, pipelined output)
    reg [2*WIDTH-1:0] interleaved_reg;

    always @(*) begin : interleave_optimized
        integer j;
        reg [2*WIDTH-1:0] temp;
        temp = {2*WIDTH{1'b0}};
        for (j = 0; j < WIDTH; j = j + 1) begin
            temp[j]         = data_a_reg[j];
            temp[j+WIDTH]   = data_b_reg[j];
        end
        // Bitwise interleaving using concatenation and shifting
        interleaved_reg = {temp[2*WIDTH-1:WIDTH], temp[WIDTH-1:0]};
    end

    // Stage 3: Register interleaved output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            interleaved_data <= {2*WIDTH{1'b0}};
            valid_out        <= 1'b0;
        end else begin
            interleaved_data <= interleaved_reg;
            valid_out        <= valid_reg;
        end
    end

endmodule