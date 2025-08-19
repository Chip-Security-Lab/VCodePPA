module serial_to_parallel_recovery #(
    parameter WIDTH = 8
)(
    input wire bit_clk,
    input wire reset,
    input wire serial_in,
    input wire frame_sync,
    output reg [WIDTH-1:0] parallel_out,
    output reg data_valid
);
    reg [WIDTH-1:0] shift_reg;
    reg [3:0] bit_count;
    
    always @(posedge bit_clk or posedge reset) begin
        if (reset) begin
            shift_reg <= {WIDTH{1'b0}};
            bit_count <= 4'h0;
            parallel_out <= {WIDTH{1'b0}};
            data_valid <= 1'b0;
        end else if (frame_sync) begin
            // Reset on frame sync
            shift_reg <= {WIDTH{1'b0}};
            bit_count <= 4'h0;
            data_valid <= 1'b0;
        end else begin
            // Shift in serial data, MSB first
            shift_reg <= {shift_reg[WIDTH-2:0], serial_in};
            bit_count <= bit_count + 4'h1;
            
            if (bit_count == WIDTH-1) begin
                // When full word received
                parallel_out <= {shift_reg[WIDTH-2:0], serial_in};
                data_valid <= 1'b1;
                bit_count <= 4'h0;
            end else begin
                data_valid <= 1'b0;
            end
        end
    end
endmodule