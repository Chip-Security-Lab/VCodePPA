//SystemVerilog
module LowPowerIVMU (
    input main_clk, rst_n,
    input [15:0] int_sources,
    input [15:0] int_mask,
    input clk_en,
    input ack_in, // Added acknowledge input for Req-Ack handshake
    output reg [31:0] data_out, // Renamed from vector_out, output data
    output reg req_out // Renamed from int_pending, output request
);
    wire gated_clk;
    reg [31:0] vectors [0:15];
    wire [15:0] pending_comb; // Use _comb suffix for combinational wires
    wire pending_any_comb;   // Use _comb suffix for combinational wires

    // Combinational logic for pending interrupts
    assign pending_comb = int_sources & ~int_mask;
    assign pending_any_comb = |pending_comb; // Compute the OR reduction combinatorially

    // Clock gating logic - uses the combinational pending status
    // This is the same clock gating as original, based on pending_any_comb
    assign gated_clk = main_clk & (clk_en | pending_any_comb);

    // Combinational logic to determine the priority index
    // This implements a 16-input priority encoder
    wire [3:0] priority_index_comb;

    assign priority_index_comb =
        pending_comb[15] ? 4'hF :
        pending_comb[14] ? 4'hE :
        pending_comb[13] ? 4'hD :
        pending_comb[12] ? 4'hC :
        pending_comb[11] ? 4'hB :
        pending_comb[10] ? 4'hA :
        pending_comb[9]  ? 4'h9 :
        pending_comb[8]  ? 4'h8 :
        pending_comb[7]  ? 4'h7 :
        pending_comb[6]  ? 4'h6 :
        pending_comb[5]  ? 4'h5 :
        pending_comb[4]  ? 4'h4 :
        pending_comb[3]  ? 4'h3 :
        pending_comb[2]  ? 4'h2 :
        pending_comb[1]  ? 4'h1 :
        4'h0; // Default to index 0 if none of the above are set (only relevant if pending_any_comb is true)

    // Initialize vector addresses
    initial begin
        vectors[0] = 32'h9000_0000 + (0 * 4);
        vectors[1] = 32'h9000_0000 + (1 * 4);
        vectors[2] = 32'h9000_0000 + (2 * 4);
        vectors[3] = 32'h9000_0000 + (3 * 4);
        vectors[4] = 32'h9000_0000 + (4 * 4);
        vectors[5] = 32'h9000_0000 + (5 * 4);
        vectors[6] = 32'h9000_0000 + (6 * 4);
        vectors[7] = 32'h9000_0000 + (7 * 4);
        vectors[8] = 32'h9000_0000 + (8 * 4);
        vectors[9] = 32'h9000_0000 + (9 * 4);
        vectors[10] = 32'h9000_0000 + (10 * 4);
        vectors[11] = 32'h9000_0000 + (11 * 4);
        vectors[12] = 32'h9000_0000 + (12 * 4);
        vectors[13] = 32'h9000_0000 + (13 * 4);
        vectors[14] = 32'h9000_0000 + (14 * 4);
        vectors[15] = 32'h9000_0000 + (15 * 4);
    end

    // Sequential logic for Req-Ack handshake
    always @(posedge gated_clk or negedge rst_n) begin
        if (!rst_n) begin
            req_out <= 1'b0;
            data_out <= 32'h0; // Initialize data_out on reset
        end else begin
            // If req_out is currently low (channel free)
            if (req_out == 1'b0) begin
                // If there is a pending interrupt, assert req and load data
                if (pending_any_comb) begin
                    req_out <= 1'b1;
                    data_out <= vectors[priority_index_comb];
                end
                // Else (no pending interrupt), req_out stays low, data_out holds
            end
            // If req_out is currently high (channel busy)
            else begin // req_out == 1'b1
                // If acknowledged, deassert req. Channel becomes free for the next cycle.
                if (ack_in) begin
                    req_out <= 1'b0;
                    // data_out holds its value. It's only updated when req_out goes high.
                end
                // Else (not acknowledged), hold req and data
            end
        end
    end
endmodule