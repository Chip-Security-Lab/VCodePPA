//SystemVerilog
module counter_based_rng_valid_ready (
    input  wire        clk,
    input  wire        reset,
    input  wire [7:0]  seed,
    input  wire        data_valid,
    output wire        data_ready,
    output reg  [15:0] rand_out,
    output reg         rand_valid,
    input  wire        rand_ready
);
    reg [7:0] counter;
    reg       next_data;

    assign data_ready = (!reset) && (!next_data);

    always @(posedge clk) begin
        if (reset) begin
            counter   <= seed;
            rand_out  <= {seed, ~seed};
            rand_valid <= 1'b0;
            next_data <= 1'b0;
        end else begin
            // Initiate new random data generation when input is valid and ready
            if (data_valid && data_ready) begin
                counter   <= seed;
                rand_out  <= {seed, ~seed};
                rand_valid <= 1'b1;
                next_data <= 1'b0;
            end
            // Generate next random number when previous output is accepted
            else if (rand_valid && rand_ready) begin
                counter   <= counter + 8'h53;
                rand_out  <= {rand_out[7:0] ^ (counter + 8'h53), rand_out[15:8] + (counter + 8'h53)};
                rand_valid <= 1'b1;
                next_data <= 1'b0;
            end
            // Hold current output if not accepted
            else if (rand_valid && !rand_ready) begin
                rand_valid <= 1'b1;
                next_data  <= 1'b1;
            end
            else begin
                rand_valid <= 1'b0;
                next_data  <= 1'b0;
            end
        end
    end
endmodule