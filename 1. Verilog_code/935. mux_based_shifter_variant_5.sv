//SystemVerilog
module mux_based_shifter (
    input clk,              // Clock signal
    input rst_n,            // Active-low reset
    
    // Input interface
    input [7:0] data_in,    // Input data
    input [2:0] shift_in,   // Shift amount
    input valid_in,         // Valid signal (replaces req)
    output ready_out,       // Ready signal (replaces ack)
    
    // Output interface
    output reg [7:0] data_out, // Output data
    output reg valid_out,      // Output valid
    input ready_in             // Input ready
);

    // Internal registers
    reg [7:0] data_reg;
    reg [2:0] shift_reg;
    reg processing;
    
    // Shifter logic
    wire [7:0] stage1, stage2, result;
    assign stage1 = shift_reg[0] ? {data_reg[6:0], data_reg[7]} : data_reg;
    assign stage2 = shift_reg[1] ? {stage1[5:0], stage1[7:6]} : stage1;
    assign result = shift_reg[2] ? {stage2[3:0], stage2[7:4]} : stage2;
    
    // Ready to accept new data when not processing or when output is being consumed
    assign ready_out = !processing || (valid_out && ready_in);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 8'h0;
            shift_reg <= 3'h0;
            processing <= 1'b0;
            valid_out <= 1'b0;
            data_out <= 8'h0;
        end else begin
            // Input handshake
            if (valid_in && ready_out) begin
                data_reg <= data_in;
                shift_reg <= shift_in;
                processing <= 1'b1;
            end
            
            // Output handshake
            if (processing && (!valid_out || ready_in)) begin
                data_out <= result;
                valid_out <= 1'b1;
                processing <= 1'b0;
            end
            
            // Clear valid when transaction completes
            if (valid_out && ready_in) begin
                valid_out <= 1'b0;
            end
        end
    end
    
endmodule