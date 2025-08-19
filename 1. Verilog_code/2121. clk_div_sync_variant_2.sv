//SystemVerilog
//IEEE 1364-2005 Verilog Standard
module clk_div_sync #(
    parameter DIV = 4
)(
    input clk_in,
    input rst_n,
    input en,
    output reg clk_out
);
    // Use exact bit width needed for counter based on DIV parameter
    reg [$clog2(DIV/2):0] counter;
    
    // Pre-compute the comparison value to reduce critical path
    localparam HALF_DIV_MINUS1 = (DIV/2) - 1;
    
    // Add buffered versions of high fanout signals
    reg en_buf1, en_buf2;
    reg rst_n_buf1, rst_n_buf2;
    wire counter_max;
    reg counter_max_buf1, counter_max_buf2;
    
    // Buffer the enable signal to reduce fanout load
    always @(posedge clk_in) begin
        en_buf1 <= en;
        en_buf2 <= en_buf1;
    end
    
    // Buffer the reset signal to reduce fanout load
    always @(posedge clk_in) begin
        rst_n_buf1 <= rst_n;
        rst_n_buf2 <= rst_n_buf1;
    end
    
    // Separate comparison logic from counter update to balance paths
    assign counter_max = (counter == HALF_DIV_MINUS1);
    
    // Buffer counter_max signal
    always @(posedge clk_in) begin
        counter_max_buf1 <= counter_max;
        counter_max_buf2 <= counter_max_buf1;
    end
    
    // Counter logic with balanced loads using buffered signals
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            counter <= '0;
        end else if (en_buf1) begin
            if (counter_max) begin
                counter <= '0;
            end else begin
                counter <= counter + 1'b1;
            end
        end
    end
    
    // Clock output logic using different buffer to balance load
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            clk_out <= 1'b0;
        end else if (en_buf2) begin
            if (counter_max_buf2) begin
                clk_out <= ~clk_out;
            end
        end
    end
endmodule