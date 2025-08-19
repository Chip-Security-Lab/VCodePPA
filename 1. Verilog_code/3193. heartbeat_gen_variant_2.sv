//SystemVerilog
module heartbeat_gen #(
    parameter IDLE_CYCLES = 1000,
    parameter PULSE_CYCLES = 50,
    parameter TOTAL_CYCLES = IDLE_CYCLES + PULSE_CYCLES,
    parameter CNT_WIDTH = $clog2(TOTAL_CYCLES)
)(
    input wire clk,
    input wire rst,
    output reg heartbeat
);

reg [CNT_WIDTH-1:0] counter;
wire [CNT_WIDTH-1:0] next_counter;

// Han-Carlson Adder implementation
wire [CNT_WIDTH-1:0] g, p;
wire [CNT_WIDTH-1:0] g_out, p_out;
wire [CNT_WIDTH-1:0] sum;

// Generate and Propagate computation
genvar i;
generate
    for (i = 0; i < CNT_WIDTH; i = i + 1) begin : gen_prop
        assign g[i] = counter[i] & 1'b1;
        assign p[i] = counter[i] ^ 1'b1;
    end
endgenerate

// Prefix computation
assign g_out[0] = g[0];
assign p_out[0] = p[0];

generate
    for (i = 1; i < CNT_WIDTH; i = i + 1) begin : prefix
        assign g_out[i] = g[i] | (p[i] & g_out[i-1]);
        assign p_out[i] = p[i] & p_out[i-1];
    end
endgenerate

// Sum computation
assign sum[0] = p[0];
generate
    for (i = 1; i < CNT_WIDTH; i = i + 1) begin : sum_gen
        assign sum[i] = p[i] ^ g_out[i-1];
    end
endgenerate

assign next_counter = sum;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        counter <= 'd0;
        heartbeat <= 1'b0;
    end else begin
        if (counter == TOTAL_CYCLES - 1) begin
            counter <= 'd0;
            heartbeat <= 1'b0;
        end else begin
            counter <= next_counter;
            if (counter == IDLE_CYCLES - 1)
                heartbeat <= 1'b1;
            else if (counter == TOTAL_CYCLES - 1)
                heartbeat <= 1'b0;
        end
    end
end

endmodule