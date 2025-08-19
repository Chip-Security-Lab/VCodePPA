//SystemVerilog
module IVMU_RoundRobin #(parameter CH=4) (
    input wire clk,
    input wire rst_n,
    input wire [CH-1:0] irq,
    output reg [CLOG2_WIDTH-1:0] current_ch
);

    // Calculate the number of bits needed for the channel index (0 to CH-1)
    // ceil(log2(CH))
    localparam integer CLOG2_WIDTH = (CH <= 1) ? 1 : $clog2(CH);

    // Internal wire for the combinational priority encoder output
    wire [CLOG2_WIDTH-1:0] current_ch_comb;

    // Combinational Priority Encoder Logic
    // This block determines the highest priority active IRQ line.
    // Priority is given to the highest index bit that is set in 'irq'.
    reg [CLOG2_WIDTH-1:0] current_ch_comb_r; // Temporary register for procedural assignment

    always @(*) begin
        // Default output value if no IRQ is active.
        // Assigning 0 selects channel 0 by default.
        current_ch_comb_r = 0;

        // Iterate from the highest possible IRQ index down to the lowest.
        // The last assignment to current_ch_comb_r in the loop will correspond
        // to the highest index 'i' for which irq[i] is high, thus implementing priority.
        if (CH > 0) begin
            for (integer i = CH-1; i >= 0; i = i - 1) begin
                if (irq[i]) begin
                    current_ch_comb_r = i;
                end
            end
        end
    end

    // Connect the combinational output from the procedural block to the wire.
    assign current_ch_comb = current_ch_comb_r;

    // Registered Output Stage
    // This sequential block registers the output of the priority encoder.
    // Adding a register here breaks the combinational path, improving timing (Fmax),
    // but adds one clock cycle latency.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset the output to a known state (channel 0).
            current_ch <= 0;
        end else begin
            // Register the combinational result on the positive clock edge.
            current_ch <= current_ch_comb;
        end
    end

endmodule