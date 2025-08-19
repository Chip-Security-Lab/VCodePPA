//SystemVerilog
module multistage_shifter(
    input wire clk,               // Clock signal
    input wire rst_n,             // Active-low reset
    input wire [7:0] data_in,     // Input data
    input wire [2:0] shift_amt,   // Shift amount
    input wire valid_in,          // Input valid signal (was req)
    output wire ready_out,        // Output ready signal (was ack)
    output reg [7:0] data_out,    // Output data
    output reg valid_out,         // Output valid signal
    input wire ready_in           // Input ready signal
);
    // Internal signals
    reg [7:0] stage0_out, stage1_out, stage2_out;
    reg [2:0] shift_amt_reg;
    reg data_valid_r;
    
    // Control logic for handshaking
    assign ready_out = ready_in || !valid_out;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_amt_reg <= 3'b0;
            data_valid_r <= 1'b0;
            valid_out <= 1'b0;
            data_out <= 8'b0;
        end else begin
            // Input handshake
            if (valid_in && ready_out) begin
                // Register input data and control signals when valid handshake occurs
                shift_amt_reg <= shift_amt;
                data_valid_r <= 1'b1;
            end else if (valid_out && ready_in) begin
                // Clear valid flag after successful output handshake
                data_valid_r <= 1'b0;
            end
            
            // Pipeline processing
            if (data_valid_r) begin
                // Stage 0: Shift by 0 or 1 bit
                stage0_out <= shift_amt_reg[0] ? {data_in[6:0], 1'b0} : data_in;
                
                // Stage 1: Shift by 0 or 2 bits
                stage1_out <= shift_amt_reg[1] ? {stage0_out[5:0], 2'b00} : stage0_out;
                
                // Stage 2: Shift by 0 or 4 bits
                stage2_out <= shift_amt_reg[2] ? {stage1_out[3:0], 4'b0000} : stage1_out;
                
                // Set output valid when processing is complete
                valid_out <= 1'b1;
                data_out <= stage2_out;
            end else if (valid_out && ready_in) begin
                // Clear valid signal when output is acknowledged
                valid_out <= 1'b0;
            end
        end
    end
endmodule