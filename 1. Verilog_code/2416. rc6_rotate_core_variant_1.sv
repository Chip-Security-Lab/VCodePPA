//SystemVerilog
module rc6_rotate_core (
    input wire clk,
    input wire rst_n,
    
    // Input interface - Valid-Ready protocol
    input wire        valid_in,
    output reg        ready_in,
    input wire [31:0] a_in,
    input wire [31:0] b_in,
    
    // Output interface - Valid-Ready protocol
    output reg        valid_out,
    input wire        ready_out,
    output reg [31:0] data_out
);
    // Internal signals
    reg [31:0] a_in_reg, b_in_reg;
    reg processing;
    
    wire [4:0] rot_offset = b_in_reg[4:0];
    wire [31:0] rotated_val = (a_in_reg << rot_offset) | (a_in_reg >> (32 - rot_offset));
    wire [31:0] added_val = rotated_val + 32'h9E3779B9; // Golden ratio
    
    // Input handshaking and data capture
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_in_reg <= 32'h0;
            b_in_reg <= 32'h0;
            processing <= 1'b0;
            ready_in <= 1'b1;
        end else begin
            if (ready_in && valid_in) begin
                // Capture input data when handshake occurs
                a_in_reg <= a_in;
                b_in_reg <= b_in;
                processing <= 1'b1;
                ready_in <= 1'b0; // Not ready for next input until current is processed
            end else if (valid_out && ready_out) begin
                // Output handshake complete, ready for new input
                processing <= 1'b0;
                ready_in <= 1'b1;
            end
        end
    end
    
    // Process data and manage output interface
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 32'h0;
            valid_out <= 1'b0;
        end else begin
            if (processing && !valid_out) begin
                // Process captured data and assert valid
                data_out <= added_val;
                valid_out <= 1'b1;
            end else if (valid_out && ready_out) begin
                // Output handshake complete, deassert valid
                valid_out <= 1'b0;
            end
        end
    end
    
endmodule