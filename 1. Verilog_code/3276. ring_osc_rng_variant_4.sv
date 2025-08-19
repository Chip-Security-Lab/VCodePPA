//SystemVerilog
module ring_osc_rng (
    input wire system_clk,
    input wire reset_n,
    output reg [7:0] random_byte
);

    // Simulating multiple oscillators with different "frequencies"
    reg [3:0] osc_counters [3:0];
    reg [3:0] osc_counters_reg [3:0]; // Pipeline register for osc_counters
    reg [3:0] osc_bits_stage1;         // Pipeline register for osc_bits
    reg [7:0] random_byte_stage1;      // Pipeline register for random_byte

    integer idx;

    // Counter update logic
    always @(posedge system_clk or negedge reset_n) begin
        if (!reset_n) begin
            osc_counters[0] <= 4'd1;
            osc_counters[1] <= 4'd2;
            osc_counters[2] <= 4'd3;
            osc_counters[3] <= 4'd4;
        end else begin
            osc_counters[0] <= osc_counters[0] + 4'd1;
            osc_counters[1] <= osc_counters[1] + 4'd2;
            osc_counters[2] <= osc_counters[2] + 4'd3;
            osc_counters[3] <= osc_counters[3] + 4'd4;
        end
    end

    // Pipeline stage 1: Register osc_counters to break combinational path
    always @(posedge system_clk or negedge reset_n) begin
        if (!reset_n) begin
            osc_counters_reg[0] <= 4'd1;
            osc_counters_reg[1] <= 4'd2;
            osc_counters_reg[2] <= 4'd3;
            osc_counters_reg[3] <= 4'd4;
        end else begin
            osc_counters_reg[0] <= osc_counters[0];
            osc_counters_reg[1] <= osc_counters[1];
            osc_counters_reg[2] <= osc_counters[2];
            osc_counters_reg[3] <= osc_counters[3];
        end
    end

    // Pipeline stage 2: Extract osc_bits from registered counters
    always @(posedge system_clk or negedge reset_n) begin
        if (!reset_n) begin
            osc_bits_stage1 <= 4'b0000;
        end else begin
            osc_bits_stage1 <= {osc_counters_reg[3][3], osc_counters_reg[2][3], osc_counters_reg[1][3], osc_counters_reg[0][3]};
        end
    end

    // Pipeline stage 3: Register random_byte input
    always @(posedge system_clk or negedge reset_n) begin
        if (!reset_n) begin
            random_byte_stage1 <= 8'h42;
        end else begin
            random_byte_stage1 <= random_byte;
        end
    end

    // Pipeline stage 4: Update random_byte output
    always @(posedge system_clk or negedge reset_n) begin
        if (!reset_n) begin
            random_byte <= 8'h42;
        end else begin
            random_byte <= {random_byte_stage1[3:0], osc_bits_stage1};
        end
    end

endmodule