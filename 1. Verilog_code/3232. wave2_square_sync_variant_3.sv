//SystemVerilog
module wave2_square_sync #(
    parameter PERIOD = 8,
    parameter SYNC_RESET = 1
)(
    input  wire clk,
    input  wire rst,
    output reg  wave_out
);
    // Counter signals
    reg [$clog2(PERIOD)-1:0] cnt;
    reg [$clog2(PERIOD)-1:0] cnt_buf1;
    reg [$clog2(PERIOD)-1:0] cnt_buf2;
    
    // Period comparison signal
    wire cnt_eq_period_m1;
    
    // Buffered counter pipeline for reducing fanout
    always @(posedge clk) begin
        cnt_buf1 <= cnt;
    end
    
    always @(posedge clk) begin
        cnt_buf2 <= cnt_buf1;
    end
    
    // Comparison logic with reduced fanout
    assign cnt_eq_period_m1 = (cnt_buf2 == PERIOD-1);

    generate
        if (SYNC_RESET) begin
            // Counter control logic
            always @(posedge clk) begin
                if (rst) begin
                    cnt <= 0;
                end else if (cnt_eq_period_m1) begin
                    cnt <= 0;
                end else begin
                    cnt <= cnt + 1;
                end
            end
            
            // Output wave generation logic
            always @(posedge clk) begin
                if (rst) begin
                    wave_out <= 0;
                end else if (cnt_eq_period_m1) begin
                    wave_out <= ~wave_out;
                end
            end
        end else begin
            // Counter control logic with async reset
            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    cnt <= 0;
                end else if (cnt_eq_period_m1) begin
                    cnt <= 0;
                end else begin
                    cnt <= cnt + 1;
                end
            end
            
            // Output wave generation logic with async reset
            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    wave_out <= 0;
                end else if (cnt_eq_period_m1) begin
                    wave_out <= ~wave_out;
                end
            end
        end
    endgenerate
endmodule