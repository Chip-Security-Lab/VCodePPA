//SystemVerilog
module one_hot_reset_dist(
    input wire clk,
    input wire [1:0] reset_select,
    input wire reset_in,
    output reg [3:0] reset_out
);
    // Pipeline stage 1 registers
    reg reset_in_stage1;
    reg [1:0] reset_select_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers
    reg [3:0] reset_decoded_stage2;
    reg valid_stage2;
    
    // Stage 1: Input capture and validation
    always @(posedge clk) begin
        reset_in_stage1 <= reset_in;
        reset_select_stage1 <= reset_select;
        valid_stage1 <= reset_in; // Valid when reset_in is asserted
    end
    
    // Stage 2: Decode reset signal based on selection
    always @(posedge clk) begin
        valid_stage2 <= valid_stage1;
        
        if (valid_stage1) begin
            case (reset_select_stage1)
                2'b00: reset_decoded_stage2 <= 4'b0001;
                2'b01: reset_decoded_stage2 <= 4'b0010;
                2'b10: reset_decoded_stage2 <= 4'b0100;
                2'b11: reset_decoded_stage2 <= 4'b1000;
                default: reset_decoded_stage2 <= 4'b0000;
            endcase
        end else begin
            reset_decoded_stage2 <= 4'b0000;
        end
    end
    
    // Final stage: Output assignment
    always @(posedge clk) begin
        if (valid_stage2) begin
            reset_out <= reset_decoded_stage2;
        end else begin
            reset_out <= 4'b0000;
        end
    end
endmodule