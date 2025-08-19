//SystemVerilog
module DCT_Compress (
    input wire clk,
    input wire rst_n,
    
    // Input interface - Valid/Ready handshake
    input wire [7:0] data_in,
    input wire valid_in,
    output wire ready_out,
    
    // Output interface - Valid/Ready handshake
    output reg [7:0] data_out,
    output reg valid_out,
    input wire ready_in
);

    // Internal signals
    wire signed [15:0] mult_result;
    wire [7:0] shifted_result;
    reg processing;
    
    // Combinational logic calculation
    assign mult_result = data_in * 16'sd23170;  // cos(π/4) * 32768
    assign shifted_result = (mult_result >>> 15) + 8'd128;
    
    // Handshaking logic
    assign ready_out = !processing || (valid_out && ready_in);
    
    // Processing state and output control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            processing <= 1'b0;
            valid_out <= 1'b0;
            data_out <= 8'd0;
        end else begin
            if (ready_out && valid_in) begin
                // Accept new data
                processing <= 1'b1;
                
                // Process and prepare output in one cycle
                data_out <= shifted_result;
                valid_out <= 1'b1;
            end else if (valid_out && ready_in) begin
                // Data has been accepted by downstream module
                valid_out <= 1'b0;
                processing <= 1'b0;
            end
        end
    end
    
endmodule