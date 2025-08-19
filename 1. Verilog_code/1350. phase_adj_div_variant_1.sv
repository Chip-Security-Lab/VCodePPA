//SystemVerilog
module phase_adj_div #(parameter PHASE_STEP=2) (
    input clk, rst, adj_up,
    output reg clk_out
);
    reg [7:0] phase;
    reg [7:0] cnt;
    reg [7:0] next_phase;
    reg [7:0] next_cnt;
    reg next_clk_out;
    wire [7:0] half_phase;

    // Pre-compute the phase adjustment
    assign half_phase = {1'b0, phase[7:1]};

    always @(*) begin
        // Phase adjustment logic using if-else
        if (adj_up) begin
            next_phase = phase + PHASE_STEP;
        end else begin
            next_phase = phase - PHASE_STEP;
        end

        // Counter reset logic using if-else
        if (cnt == 200 - phase) begin
            next_cnt = 8'd0;
        end else begin
            next_cnt = cnt + 8'd1;
        end

        // Clock output logic using if-else
        if (cnt < 100 - half_phase) begin
            next_clk_out = 1'b1;
        end else begin
            next_clk_out = 1'b0;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            cnt <= 8'd0;
            phase <= 8'd0;
            clk_out <= 1'b0;
        end else begin
            phase <= next_phase;
            cnt <= next_cnt;
            clk_out <= next_clk_out;
        end
    end
endmodule