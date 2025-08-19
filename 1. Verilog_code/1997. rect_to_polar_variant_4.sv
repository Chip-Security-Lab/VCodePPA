//SystemVerilog
module rect_to_polar #(
    parameter WIDTH = 16,
    parameter ITERATIONS = 8
)(
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     in_valid,
    input  wire signed [WIDTH-1:0]  x_in,
    input  wire signed [WIDTH-1:0]  y_in,
    output reg                      out_valid,
    output reg  [WIDTH-1:0]         magnitude,
    output reg  [WIDTH-1:0]         angle
);

    // CORDIC atan lookup table with buffer register
    reg signed [WIDTH-1:0] atan_table_mem [0:ITERATIONS-1];
    reg signed [WIDTH-1:0] atan_table_buf [0:ITERATIONS-1];
    integer i_atan;

    initial begin
        atan_table_mem[0] = 32'd2949120;
        atan_table_mem[1] = 32'd1740992;
        atan_table_mem[2] = 32'd919872;
        atan_table_mem[3] = 32'd466944;
        atan_table_mem[4] = 32'd234368;
        atan_table_mem[5] = 32'd117312;
        atan_table_mem[6] = 32'd58688;
        atan_table_mem[7] = 32'd29312;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i_atan = 0; i_atan < ITERATIONS; i_atan = i_atan + 1) begin
                atan_table_buf[i_atan] <= 0;
            end
        end else begin
            for (i_atan = 0; i_atan < ITERATIONS; i_atan = i_atan + 1) begin
                atan_table_buf[i_atan] <= atan_table_mem[i_atan];
            end
        end
    end

    // Buffer register for signed control signal
    reg signed signed_buf;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            signed_buf <= 1'b0;
        else
            signed_buf <= 1'b1; // If you want to use this, define its use; placeholder for "signed" signal buffer
    end

    // Multi-stage pipeline registers for x_pipe, y_pipe, z_pipe (buffered)
    reg signed [WIDTH-1:0] x_pipe      [0:ITERATIONS];
    reg signed [WIDTH-1:0] x_pipe_buf  [0:ITERATIONS];
    reg signed [WIDTH-1:0] y_pipe      [0:ITERATIONS];
    reg signed [WIDTH-1:0] y_pipe_buf  [0:ITERATIONS];
    reg        [WIDTH-1:0] z_pipe      [0:ITERATIONS];
    reg        [WIDTH-1:0] z_pipe_buf  [0:ITERATIONS];
    reg                    valid_pipe  [0:ITERATIONS];
    reg                    valid_pipe_buf [0:ITERATIONS];

    integer stage;

    // Pipeline register initialization and buffering for fanout reduction
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (stage = 0; stage <= ITERATIONS; stage = stage + 1) begin
                x_pipe[stage]        <= 0;
                x_pipe_buf[stage]    <= 0;
                y_pipe[stage]        <= 0;
                y_pipe_buf[stage]    <= 0;
                z_pipe[stage]        <= 0;
                z_pipe_buf[stage]    <= 0;
                valid_pipe[stage]    <= 1'b0;
                valid_pipe_buf[stage]<= 1'b0;
            end
        end else begin
            // Stage 0: Input registration
            x_pipe[0]        <= x_in;
            x_pipe_buf[0]    <= x_in;
            y_pipe[0]        <= y_in;
            y_pipe_buf[0]    <= y_in;
            z_pipe[0]        <= 0;
            z_pipe_buf[0]    <= 0;
            valid_pipe[0]    <= in_valid;
            valid_pipe_buf[0]<= in_valid;

            // Pipeline stages: Iterative CORDIC with fanout buffering
            for (stage = 0; stage < ITERATIONS; stage = stage + 1) begin
                // Buffer fanout for each stage
                x_pipe_buf[stage]    <= x_pipe[stage];
                y_pipe_buf[stage]    <= y_pipe[stage];
                z_pipe_buf[stage]    <= z_pipe[stage];
                valid_pipe_buf[stage]<= valid_pipe[stage];

                if (valid_pipe_buf[stage]) begin
                    if (y_pipe_buf[stage] >= 0) begin
                        x_pipe[stage+1]     <= x_pipe_buf[stage] + (y_pipe_buf[stage] >>> stage);
                        y_pipe[stage+1]     <= y_pipe_buf[stage] - (x_pipe_buf[stage] >>> stage);
                        z_pipe[stage+1]     <= z_pipe_buf[stage] + atan_table_buf[stage];
                    end else begin
                        x_pipe[stage+1]     <= x_pipe_buf[stage] - (y_pipe_buf[stage] >>> stage);
                        y_pipe[stage+1]     <= y_pipe_buf[stage] + (x_pipe_buf[stage] >>> stage);
                        z_pipe[stage+1]     <= z_pipe_buf[stage] - atan_table_buf[stage];
                    end
                    valid_pipe[stage+1] <= valid_pipe_buf[stage];
                end else begin
                    x_pipe[stage+1]     <= x_pipe[stage+1];
                    y_pipe[stage+1]     <= y_pipe[stage+1];
                    z_pipe[stage+1]     <= z_pipe[stage+1];
                    valid_pipe[stage+1] <= 1'b0;
                end
            end
            // Buffer last stage
            x_pipe_buf[ITERATIONS]     <= x_pipe[ITERATIONS];
            y_pipe_buf[ITERATIONS]     <= y_pipe[ITERATIONS];
            z_pipe_buf[ITERATIONS]     <= z_pipe[ITERATIONS];
            valid_pipe_buf[ITERATIONS] <= valid_pipe[ITERATIONS];
        end
    end

    // Output registration using buffer
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            magnitude <= 0;
            angle     <= 0;
            out_valid <= 1'b0;
        end else begin
            magnitude <= x_pipe_buf[ITERATIONS];
            angle     <= z_pipe_buf[ITERATIONS];
            out_valid <= valid_pipe_buf[ITERATIONS];
        end
    end

endmodule