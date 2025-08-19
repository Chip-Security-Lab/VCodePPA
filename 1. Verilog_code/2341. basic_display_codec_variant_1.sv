//SystemVerilog
module basic_display_codec (
    input wire clk,
    input wire rst_n,
    
    // Input interface with Valid-Ready handshake
    input wire [7:0] pixel_in,
    input wire valid_in,
    output reg ready_out,
    
    // Output interface with Valid-Ready handshake
    output reg [15:0] display_out,
    output reg valid_out,
    input wire ready_in
);
    
    // Internal signals
    reg [15:0] display_data;
    reg data_valid;
    
    // Input handshake logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ready_out <= 1'b0;
            data_valid <= 1'b0;
            display_data <= 16'h0000;
        end else begin
            // Accept new data when valid_in is asserted and we're ready or data has been transmitted
            if (valid_in && (ready_out || valid_out && ready_in)) begin
                display_data <= {pixel_in[7:5], 5'b0, pixel_in[4:2], 5'b0, pixel_in[1:0], 6'b0};
                data_valid <= 1'b1;
                ready_out <= 1'b0; // De-assert ready until current data is transmitted
            end else if (valid_out && ready_in) begin
                // Data has been accepted by downstream module
                data_valid <= 1'b0;
                ready_out <= 1'b1; // Ready to accept new data
            end else if (!data_valid && !valid_out) begin
                // Idle state - ready to accept new data
                ready_out <= 1'b1;
            end
        end
    end
    
    // Output handshake logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            display_out <= 16'h0000;
            valid_out <= 1'b0;
        end else begin
            if (data_valid && !valid_out) begin
                // New data available to be transmitted
                display_out <= display_data;
                valid_out <= 1'b1;
            end else if (valid_out && ready_in) begin
                // Data has been accepted by downstream module
                valid_out <= 1'b0;
            end
        end
    end
    
endmodule