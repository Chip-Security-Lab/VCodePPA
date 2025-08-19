//SystemVerilog - IEEE 1364-2005
module quadrature_clk_gen(
    input wire reference_clk,
    input wire reset_n,
    output reg I_clk,  // In-phase clock
    output reg Q_clk   // Quadrature clock (90° phase shift)
);
    // Use a 2-bit counter instead of toggle logic
    reg [1:0] counter;
    
    // Buffered reference clock for counter logic
    reg reference_clk_buf1, reference_clk_buf2;
    
    // Buffered counter signals
    reg [1:0] counter_buf1, counter_buf2;
    
    // Reference clock buffering
    always @(*) begin
        reference_clk_buf1 = reference_clk;
        reference_clk_buf2 = reference_clk;
    end
    
    // More efficient counter implementation with buffered clock
    always @(posedge reference_clk_buf1 or negedge reset_n) begin
        if (!reset_n) begin
            counter <= 2'b00;
        end else begin
            counter <= counter + 1'b1;
        end
    end
    
    // Counter value buffering to reduce fan-out load
    always @(posedge reference_clk_buf1 or negedge reset_n) begin
        if (!reset_n) begin
            counter_buf1 <= 2'b00;
            counter_buf2 <= 2'b00;
        end else begin
            counter_buf1 <= counter;
            counter_buf2 <= counter;
        end
    end
    
    // Generate I_clk directly from counter MSB via buffer
    always @(posedge reference_clk_buf1 or negedge reset_n) begin
        if (!reset_n) begin
            I_clk <= 1'b0;
        end else begin
            I_clk <= counter_buf1[1];
        end
    end
    
    // Generate Q_clk with phase shift using separate counter buffer
    always @(negedge reference_clk_buf2 or negedge reset_n) begin
        if (!reset_n) begin
            Q_clk <= 1'b0;
        end else begin
            Q_clk <= counter_buf2[1];
        end
    end
endmodule