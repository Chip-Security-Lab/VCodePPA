//SystemVerilog
module pll_clock_gen(
    input refclk,
    input reset,
    input req,               // Changed from valid
    output reg ack,          // Changed from ready
    input [3:0] mult_factor,
    input [3:0] div_factor,
    output reg outclk
);
    reg [3:0] mult_count;
    reg [3:0] mult_factor_reg, div_factor_reg;
    reg data_received;
    reg prev_req;            // Added to detect req transitions
    
    always @(posedge refclk or posedge reset) begin
        if (reset) begin
            mult_count <= 4'd0;
            outclk <= 1'b0;
            ack <= 1'b0;     // Initialize ack to 0 (different from ready)
            data_received <= 1'b0;
            prev_req <= 1'b0;
        end else begin
            prev_req <= req;
            
            // Detect rising edge of req when not processing data
            if (req && !prev_req && !data_received) begin
                mult_factor_reg <= mult_factor;
                div_factor_reg <= div_factor;
                data_received <= 1'b1;
                ack <= 1'b1;  // Acknowledge the request
            end
            
            // Reset acknowledge after sender deasserts request
            if (!req && prev_req) begin
                ack <= 1'b0;
            end
            
            if (data_received) begin
                if (mult_count >= mult_factor_reg - 1) begin
                    mult_count <= 4'd0;
                    outclk <= ~outclk;
                    data_received <= 1'b0;  // Ready for new data
                end else begin
                    mult_count <= mult_count + 1'b1;
                end
            end
        end
    end
endmodule