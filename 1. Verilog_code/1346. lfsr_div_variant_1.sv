//SystemVerilog
module lfsr_div #(
    parameter POLY = 8'hB4
)(
    input  wire clk,
    input  wire rst,
    output reg  clk_out
);
    // LFSR state registers
    reg  [7:0] lfsr_r;
    reg  [7:0] lfsr_next;
    
    // Pipeline stage registers
    reg        feedback_r;
    reg        output_valid_r;
    
    // Datapath control signals
    wire       feedback_bit;
    wire       zero_detect;
    
    // ------------------------------------------
    // Stage 1: Generate feedback and next state
    // ------------------------------------------
    assign feedback_bit = lfsr_r[7];
    
    always @(posedge clk) begin
        if (rst) begin
            feedback_r <= 1'b1;
            lfsr_next <= 8'hFF;
        end else begin
            feedback_r <= feedback_bit;
            lfsr_next <= {lfsr_r[6:0], 1'b0} ^ ({8{feedback_bit}} & POLY);
        end
    end
    
    // ------------------------------------------
    // Stage 2: Update LFSR state and detect zero
    // ------------------------------------------
    assign zero_detect = (lfsr_next == 8'h00);
    
    always @(posedge clk) begin
        if (rst) begin
            lfsr_r <= 8'hFF;
            output_valid_r <= 1'b0;
        end else begin
            lfsr_r <= lfsr_next;
            output_valid_r <= zero_detect;
        end
    end
    
    // ------------------------------------------
    // Stage 3: Generate output clock
    // ------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            clk_out <= 1'b0;
        end else begin
            clk_out <= output_valid_r;
        end
    end
    
endmodule