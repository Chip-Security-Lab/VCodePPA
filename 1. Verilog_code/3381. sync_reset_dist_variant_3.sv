//SystemVerilog
module sync_reset_dist (
    input wire clk,
    input wire rst_in,
    input wire ready,      // Ready signal from receiver
    output reg valid,      // Valid signal to receiver
    output reg [7:0] rst_out
);

    // Internal reset value register
    reg [7:0] reset_value;

    // Reset value generation logic
    always @(posedge clk) begin
        if (rst_in) begin
            reset_value <= 8'hFF;  // All outputs active
        end else begin
            reset_value <= 8'h00;  // All outputs inactive
        end
    end

    // Valid signal control logic
    always @(posedge clk) begin
        valid <= 1'b1;  // Always assert valid signal
    end

    // Data transfer logic with handshake
    always @(posedge clk) begin
        if (valid && ready) begin
            rst_out <= reset_value;  // Transfer data when valid and ready are both asserted
        end
    end

endmodule