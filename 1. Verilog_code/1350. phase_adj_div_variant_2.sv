//SystemVerilog
module phase_adj_div #(parameter PHASE_STEP=2) (
    input clk, rst, adj_up,
    output reg clk_out
);
    reg [7:0] phase;
    reg [7:0] cnt;
    reg [7:0] phase_next;
    reg [7:0] threshold;
    reg [7:0] half_threshold;
    
    // Pipeline stage 1: Calculate next phase value
    always @(posedge clk) begin
        if(rst) begin
            phase_next <= 0;
            phase <= 0;
        end else begin
            phase_next <= adj_up ? phase + PHASE_STEP : phase - PHASE_STEP;
            phase <= phase_next;
        end
    end
    
    // Pipeline stage 2: Calculate threshold values
    always @(posedge clk) begin
        if(rst) begin
            threshold <= 200;
            half_threshold <= 100;
        end else begin
            threshold <= 200 - phase;
            half_threshold <= 100 - phase/2;
        end
    end
    
    // Pipeline stage 3: Counter and output logic
    always @(posedge clk) begin
        if(rst) begin
            cnt <= 0;
            clk_out <= 0;
        end else begin
            cnt <= (cnt == threshold) ? 0 : cnt + 1;
            clk_out <= (cnt < half_threshold);
        end
    end
endmodule