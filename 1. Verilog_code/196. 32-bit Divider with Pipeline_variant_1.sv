//SystemVerilog
module divider_pipeline_32bit (
    input clk,
    input rst_n,
    
    // Input interface
    input [31:0] dividend,
    input [31:0] divisor,
    input valid_in,
    output reg ready_in,
    
    // Output interface
    output reg [31:0] quotient,
    output reg [31:0] remainder,
    output reg valid_out,
    input ready_out
);

// Internal signals
reg [31:0] dividend_reg, divisor_reg;
reg [31:0] quotient_next, remainder_next;
reg processing, output_valid;
reg [2:0] div_counter; // Counter for division pipeline stages

// Input handshake logic
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ready_in <= 1'b1;
        processing <= 1'b0;
        dividend_reg <= 32'b0;
        divisor_reg <= 32'b0;
        div_counter <= 3'b0;
    end else begin
        if (ready_in && valid_in) begin
            // Accept new data
            dividend_reg <= dividend;
            divisor_reg <= divisor;
            processing <= 1'b1;
            ready_in <= 1'b0;
            div_counter <= 3'd1; // Start pipeline counter
        end else if (processing) begin
            if (div_counter < 3'd4) begin
                // Continue processing pipeline stages
                div_counter <= div_counter + 1'b1;
            end else begin
                // Division complete, prepare for output
                processing <= 1'b0;
                output_valid <= 1'b1;
                
                // Calculate division results
                quotient_next <= dividend_reg / divisor_reg;
                remainder_next <= dividend_reg % divisor_reg;
                
                // Only accept new input if output is transferred or will be transferred
                if (valid_out && ready_out) 
                    ready_in <= 1'b1;
            end
        end else if (output_valid && valid_out && ready_out) begin
            // Output has been transferred, ready for new input
            output_valid <= 1'b0;
            ready_in <= 1'b1;
        end
    end
end

// Output handshake logic
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        quotient <= 32'b0;
        remainder <= 32'b0;
        valid_out <= 1'b0;
    end else begin
        if (output_valid && !valid_out) begin
            // New result available, assert valid
            quotient <= quotient_next;
            remainder <= remainder_next;
            valid_out <= 1'b1;
        end else if (valid_out && ready_out) begin
            // Result has been accepted, deassert valid
            valid_out <= 1'b0;
        end
    end
end

endmodule