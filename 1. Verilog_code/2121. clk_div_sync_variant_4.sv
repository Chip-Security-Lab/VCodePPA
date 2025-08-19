//SystemVerilog
module clk_div_sync #(
    parameter DIV = 4
)(
    input clk_in,
    input rst_n,
    input en,
    output reg clk_out
);
    reg [31:0] counter;
    reg en_buf1, en_buf2;  // Buffered enable signals
    reg rst_n_buf1, rst_n_buf2;  // Buffered reset signals
    reg toggle_clk;  // Internal toggle signal
    
    // Non-restoring division implementation for DIV/2 calculation
    reg [31:0] div_threshold;
    reg [31:0] dividend, divisor;
    reg [31:0] quotient;
    reg [31:0] partial_remainder;
    reg [5:0] div_state;
    reg div_done, div_start;
    
    // Buffering high fanout control signals
    always @(posedge clk_in) begin
        en_buf1 <= en;
        en_buf2 <= en_buf1;
        rst_n_buf1 <= rst_n;
        rst_n_buf2 <= rst_n_buf1;
    end
    
    // Non-restoring division state machine
    always @(posedge clk_in) begin
        if (!rst_n_buf1) begin
            div_state <= 6'd0;
            div_start <= 1'b1;
            div_done <= 1'b0;
            div_threshold <= 32'd0;
            dividend <= {1'b0, DIV[30:0]};
            divisor <= 32'd2;
            quotient <= 32'd0;
            partial_remainder <= 32'd0;
        end else if (div_start) begin
            div_start <= 1'b0;
            div_state <= 6'd1;
            partial_remainder <= {32'd0};
            quotient <= 32'd0;
        end else if (!div_done) begin
            case (div_state)
                6'd1: begin
                    // Initialize for division
                    partial_remainder <= {31'd0, dividend[31]};
                    quotient <= {dividend[30:0], 1'b0};
                    div_state <= 6'd2;
                end
                6'd2: begin
                    // Perform subtraction or addition based on sign of partial remainder
                    if (partial_remainder[31] == 1'b0) begin
                        // Partial remainder is positive, perform subtraction
                        partial_remainder <= {partial_remainder[30:0], quotient[31]} - divisor;
                    end else begin
                        // Partial remainder is negative, perform addition
                        partial_remainder <= {partial_remainder[30:0], quotient[31]} + divisor;
                    end
                    div_state <= 6'd3;
                end
                6'd3: begin
                    // Shift and set quotient bit
                    quotient <= {quotient[30:0], ~partial_remainder[31]};
                    
                    if (div_state >= 6'd33) begin
                        // Division complete after 32 iterations
                        div_state <= 6'd34;
                    end else begin
                        div_state <= div_state + 1'b1;
                        if (div_state == 6'd33) begin
                            // Handle final quotient correction
                            if (partial_remainder[31] == 1'b1) begin
                                quotient <= {quotient[30:0], 1'b0} - 1'b1;
                            end else begin
                                quotient <= {quotient[30:0], 1'b1};
                            end
                        end
                    end
                end
                6'd34: begin
                    // Correct the quotient if remainder is negative
                    if (partial_remainder[31] == 1'b1) begin
                        partial_remainder <= partial_remainder + divisor;
                    end
                    div_state <= 6'd35;
                end
                6'd35: begin
                    // Division complete
                    div_threshold <= quotient - 1'b1;
                    div_done <= 1'b1;
                    div_state <= 6'd0;
                end
                default: div_state <= 6'd0;
            endcase
        end
    end
    
    // Counter logic with buffered control signals
    always @(posedge clk_in) begin
        if (!rst_n_buf1) begin
            counter <= 32'd0;
            toggle_clk <= 1'b0;
        end else if (en_buf1 && div_done) begin
            if (counter >= div_threshold) begin
                counter <= 32'd0;
                toggle_clk <= ~toggle_clk;
            end else begin
                counter <= counter + 1'b1;
            end
        end
    end
    
    // Output clock generation with buffered control signals
    always @(posedge clk_in) begin
        if (!rst_n_buf2) begin
            clk_out <= 1'b0;
        end else if (en_buf2) begin
            clk_out <= toggle_clk;
        end
    end
endmodule