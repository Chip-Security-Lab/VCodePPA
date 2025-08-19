//SystemVerilog
module DCT_Compress (
    input wire clk,
    input wire rst_n,
    input wire valid_in,
    input wire [7:0] data_in,
    output wire ready_out,
    output reg valid_out,
    output reg [7:0] data_out
);
    // Internal signals
    wire signed [15:0] mult_result;
    reg signed [15:0] sum;
    reg processing;
    reg ready_for_input;
    
    // Handshake control
    assign ready_out = ready_for_input;
    
    // Multiplication operation in combinational logic
    assign mult_result = data_in * 8'd23170;  // cos(π/4) * 32768
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum <= 16'd0;
            data_out <= 8'd0;
            valid_out <= 1'b0;
            processing <= 1'b0;
            ready_for_input <= 1'b1;
        end else begin
            // Valid-Ready handshake logic
            if (ready_for_input && valid_in) begin
                // Capture input data
                sum <= mult_result;
                processing <= 1'b1;
                ready_for_input <= 1'b0;
            end
            
            if (processing) begin
                // Complete processing and assert valid_out
                data_out <= (sum >>> 15) + 8'd128;
                valid_out <= 1'b1;
                processing <= 1'b0;
            end
            
            if (valid_out) begin
                // Complete output transaction
                valid_out <= 1'b0;
                ready_for_input <= 1'b1;
            end
        end
    end
endmodule